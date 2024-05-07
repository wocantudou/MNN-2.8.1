//
//  MetalDeconvolution.mm
//  MNN
//
//  Created by MNN on 2019/01/30.
//  Copyright © 2018, Alibaba Group Holding Limited
//

#import "backend/metal/MetalDeconvolution.hpp"
#import "core/ConvolutionCommon.hpp"
#import "backend/metal/MNNMetalContext.h"
#import "core/Macro.h"
#import "backend/metal/MetalBackend.hpp"

#if MNN_METAL_ENABLED
namespace MNN {

static int leastCommonMultiple(int m, int n) {
    int a = m, b = n;
    while(a != b){
        if (a > b){
            a = a - b;
        } else {
            b = b - a;
        }
    }
    return m * n / a;
}

template <typename FType, typename TType>
static id<MTLBuffer> weightForDeconv(MNNMetalContext *context, int group, int oc, int ic, int kh, int kw,
                                     const FType *src) {
    auto goc    = oc / group;
    auto gic    = ic / group;
    auto goc_4  = UP_DIV(goc, 4);
    auto gic_4  = UP_DIV(gic, 4);
    auto buffer = [context newDeviceBuffer:group * goc_4 * gic_4 * kw * kh * 16 * sizeof(TType) access:CPUWriteOnly];
    auto dst    = (TType *)buffer.contents;

    for (int g = 0; g < group; g++) {
        for (int i = 0; i < gic; i++) {
            for (int o = 0; o < goc; o++) {
                for (int h = 0; h < kh; h++) {
                    for (int w = 0; w < kw; w++) {
                        auto zo = o / 4, ro = o % 4;
                        auto zi = i / 4, ri = i % 4;
                        // to   [g][o/4][i/4][h][w][16]
                        dst[(g * goc_4 * gic_4 * kh * kw + zo * gic_4 * kh * kw + zi * kh * kw + h * kw + w) * 16 +
                            ro * 4 + ri] =
                            // from [g][i][o][h][w]
                            //                            src[ g * goc   * gic   * kh * kw +  i * goc   * kh * kw +  o *
                            //                            kh * kw + h * kw + w];
                            *src++;
                    }
                }
            }
        }
    }
    return buffer;
}

template <typename FType, typename TType>
static id<MTLBuffer> weightForDepthwise(MNNMetalContext *context, int group, int kh, int kw, const FType *src) {
    auto buffer = [context newDeviceBuffer:UP_DIV(group, 4) * 4 * kw * kh * sizeof(TType) access:CPUWriteOnly];
    auto dst    = (TType *)buffer.contents;
    for (int g = 0; g < group; g++) {
        auto z = g / 4, r = g % 4;
        auto z_dst = dst + z * kh * kw * 4 + r;
#pragma clang loop vectorize(enable)
        for (int h = 0; h < kh; h++) {
#pragma clang loop vectorize(enable) unroll(enable)
            for (int w = 0; w < kw; w++) {
                // to   [g/4][h][w][4]
                // from [g][h][w]
                // dst[(z * kh * kw + h * kw + w) * 4 + r] =
                // src[ g * kh * kw + h * kw + w];
                z_dst[(h * kw + w) * 4] = *src++;
            }
        }
    }
    return buffer;
}

template <typename TType>
id<MTLBuffer> weightForDeconv(MNNMetalContext *context, bool depthwise, const Convolution2D *deconv,
                                     ConvolutionCommon::Int8Common *qnt) {
    auto size   = qnt ? qnt->weightFloat.size() : deconv->weight()->size();
    auto common = deconv->common();
    auto kw     = common->kernelX();
    auto kh     = common->kernelY();
    auto group  = common->group();
    auto oc     = common->outputCount();
    auto ic     = size / kw / kh / (oc / group);
    if (depthwise) {
        return weightForDepthwise<float, TType>(context, group, kh, kw,
                                                      qnt ? qnt->weightFloat.get() : deconv->weight()->data());
    } else {
        return weightForDeconv<float, TType>(context, group, oc, ic, kh, kw,
                                                   qnt ? qnt->weightFloat.get() : deconv->weight()->data());
    }
}

static id<MTLBuffer> biasForDeconv(MNNMetalContext *context, const Convolution2D *deconv, bool fp16) {
    auto bias = deconv->bias();
    if (!bias || bias->size() == 0)
        return [context newDeviceBuffer:0 access:CPUTransparent];

    auto oc     = deconv->common()->outputCount();
    int bytes = 4;
    if (fp16) {
        bytes = 2;
    }
    auto buffer = [context newDeviceBuffer:UP_DIV(oc, 4) * 4 * bytes access:CPUWriteOnly];
    auto src    = bias->data();
    if (fp16) {
        auto dst    = (__fp16 *)buffer.contents;
        for (int i = 0; i < oc; i++) {
            dst[i] = src[i];
        }
    } else {
        auto dst    = (float *)buffer.contents;
        for (int i = 0; i < oc; i++) {
            dst[i] = src[i];
        }
    }
    return buffer;
}

MetalDeconvolution::MetalDeconvolution(Backend *backend, const MNN::Op *op) : MetalExecution(backend) {
    auto context = (__bridge MNNMetalContext *)static_cast<MetalBackend *>(backend)->context();
    auto mtbn = static_cast<MetalBackend *>(backend);
    auto deconv  = op->main_as_Convolution2D();
    auto common  = deconv->common();
    mOp          = op;
    mDepthwise   = op->type() == MNN::OpType_DeconvolutionDepthwise;
    mGroup       = common->group();
    mKernelX     = common->kernelX();
    mKernelY     = common->kernelY();
    mPadMode     = common->padMode();
    mPadX        = common->padX();
    mPadY        = common->padY();
    mStrideX     = common->strideX();
    mStrideY     = common->strideY();
    mDilateX     = common->dilateX();
    mDilateY     = common->dilateY();
    mActivationType = common->relu() ? 1 : (common->relu6() ? 2 : 0);

    // forcy downgrade to float like what CPU does
    std::shared_ptr<ConvolutionCommon::Int8Common> qnt = NULL;
    if (deconv->quanParameter()) {
        qnt = ConvolutionCommon::load(deconv, backend, true);
    }
    if (mtbn->useFp16InsteadFp32()) {
        mWeight = weightForDeconv<__fp16>(context, mDepthwise, deconv, qnt.get());
    } else {
        mWeight = weightForDeconv<float>(context, mDepthwise, deconv, qnt.get());
    }
    mBias   = biasForDeconv(context, deconv, mtbn->useFp16InsteadFp32());
    if (mDepthwise) {
        mPipeline = [context pipelineWithName:@"deconv_depthwise" fp16:mtbn->useFp16InsteadFp32()];
    } else {
        mPipeline = [context pipelineWithName:@"deconv" fp16:mtbn->useFp16InsteadFp32()];
    }
}

ErrorCode MetalDeconvolution::onResize(const std::vector<Tensor *> &inputs, const std::vector<Tensor *> &outputs) {
    auto backend = static_cast<MetalBackend *>(this->backend());
    auto context = (__bridge MNNMetalContext *)backend->context();
    auto input = inputs[0], output = outputs[0];
    int iw = input->width(), ih = input->height(), iz = UP_DIV(input->channel(), 4);
    int ow = output->width(), oh = output->height(), oz = UP_DIV(output->channel(), 4);
    int ob = output->batch();

    auto pad = ConvolutionCommon::convolutionTransposePad(input, output, mOp->main_as_Convolution2D()->common());
    const int padX  = pad.first;
    const int padY = pad.second;
    
    // const buffer
    auto deltaKy = leastCommonMultiple(mDilateY, mStrideY) / mDilateY;
    auto deltaKx = leastCommonMultiple(mDilateX, mStrideX) / mDilateX;

    int consts[] = {
        iw,
        ih,
        iw * ih,
        iz,
        ow,
        oh,
        ow * oh,
        oz,
        mKernelX,
        mKernelY,
        mKernelX * mKernelY,
        mStrideX,
        mStrideY,
        padX,
        padY,
        mDilateX,
        mDilateY,
        deltaKy,
        deltaKx,
        deltaKy * mDilateY / mStrideY,
        deltaKx * mDilateX / mStrideX,
        mBias.length > 0,
        ob,
        mActivationType
    };
    mConstBuffer = [context newDeviceBuffer:sizeof(consts) bytes:consts access:CPUWriteOnly];
    
    mThreads = [context computeBestGroupAndLocal:mPipeline threads:MTLSizeMake((NSUInteger) ow, (NSUInteger)oh, (NSUInteger)oz * ob)];
    return NO_ERROR;
}

void MetalDeconvolution::onEncode(const std::vector<Tensor *> &inputs, const std::vector<Tensor *> &outputs, id<MTLComputeCommandEncoder> encoder) {
        auto input = inputs[0], output = outputs[0];
    [encoder setComputePipelineState:mPipeline];
    [encoder setBuffer:(id<MTLBuffer>)((MetalRuntimeAllocator::MetalBufferAlloc *)input->deviceId())->getBuffer() offset:TensorUtils::getDescribe(input)->extra.offset atIndex:0];
    [encoder setBuffer:(id<MTLBuffer>)((MetalRuntimeAllocator::MetalBufferAlloc *)output->deviceId())->getBuffer() offset:TensorUtils::getDescribe(output)->extra.offset atIndex:1];
    [encoder setBuffer:mConstBuffer offset:0 atIndex:2];
    [encoder setBuffer:mWeight offset:0 atIndex:3];
    [encoder setBuffer:mBias offset:0 atIndex:4];
    [encoder dispatchThreadgroups:mThreads.first threadsPerThreadgroup:mThreads.second];
}

class MetalDeconvolutionCreator : public MetalBackend::Creator {
public:
    virtual Execution *onCreate(const std::vector<Tensor *> &inputs, const MNN::Op *op, Backend *backend, const std::vector<Tensor *>& outputs) const {
        if (inputs.size() > 1) {
            MNN_PRINT("multi input deconv for metal not supoort!\n");
            return nullptr;
        }
        return new MetalDeconvolution(backend, op);
    }
};
REGISTER_METAL_OP_CREATOR(MetalDeconvolutionCreator, OpType_Deconvolution);
REGISTER_METAL_OP_CREATOR(MetalDeconvolutionCreator, OpType_DeconvolutionDepthwise);
} // namespace MNN
#endif /* MNN_METAL_ENABLED */
