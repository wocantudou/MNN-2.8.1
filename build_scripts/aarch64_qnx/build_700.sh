set -e
# Debug/Release
build_type=Release

source /home/wensha2/workspace/toolchain/sv-g6sh-qnx-system-sdk/qnxsdp-env.sh
cd ../../
build_dir="cmake_build/build_aarch64_qnx700/"
if [ ! -d ${build_dir} ];then
	mkdir -p ${build_dir}
fi

project_root_path=$(pwd)
echo "${project_root_path}"

cd ${build_dir}

rm -rf *

cmake	-DCMAKE_GENERATOR="Unix Makefiles"														\
		-DCMAKE_TOOLCHAIN_FILE=${project_root_path}/cmake_add/aarch64_qnx700.toolchain.cmake	\
		-DCMAKE_BUILD_TYPE=${build_type}														\
		${project_root_path}
make -j4

if [ "${build_type}" == "Debug" ];then
	exit
else
	echo "################################################## Make Build Target #################"
fi