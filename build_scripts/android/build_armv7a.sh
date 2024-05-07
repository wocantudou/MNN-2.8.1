set -e
#-----------------------------------------------------------------
# 172.20.31.106
#-----------------------------------------------------------------
# NDK_ROOT=/data/boshao/android-ndk-r16b

#-----------------------------------------------------------------
# 172.20.191.53
#-----------------------------------------------------------------
NDK_ROOT=/home/wensha2/workspace/toolchain/android-ndk-r16b
android_ndk=${NDK_ROOT}
toolchain=${NDK_ROOT}/build/cmake/android.toolchain.cmake
build_type=Release
android_abi="armeabi-v7a"
android_platform=android-17
android_arm_neon=ON
#android_stl=gnustl_static
android_stl=c++_static
#androidchain=gcc
androidchain=clang

cd ../../

build_dir="cmake_build/build_armeabi-v7a/"
if [ ! -d ${build_dir} ];then
	mkdir -p ${build_dir}
fi

project_root_path=$(pwd)
echo "${project_root_path}"

cd ${build_dir}

rm -rf *
cmake	-DBUILD_BASE_UTILS_LIB_TEST=ON						\
		-DBUILD_WITH_EASY_PROFILER=ON						\
		-DANDROID_ABI=${android_abi}                        \
		-DCMAKE_TOOLCHAIN_FILE=${toolchain}                 \
		-DANDROID_PLATFORM=${android_platform}              \
		-DCMAKE_BUILD_TYPE=${build_type}                    \
		-DANDROID_ARM_NEON=${android_arm_neon}              \
		-DANDROID_STL=${android_stl}                        \
		-DANDROID_TOOLCHAIN=${androidchain}					\
		${project_root_path}
make -j4

if [ "${build_type}" == "Debug" ];then
	exit
else
	echo "################################################## Make Build Target #################"
fi