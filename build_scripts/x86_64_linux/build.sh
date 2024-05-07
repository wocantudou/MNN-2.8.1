#-----------------------------------------------------------------
# 172.20.31.106
#-----------------------------------------------------------------
set -e
# Debug/Release
build_type=Release

cd ../../
build_dir="cmake_build/build_x86_64_linux/"
if [ ! -d ${build_dir} ];then
	mkdir -p ${build_dir}
fi

project_root_path=$(pwd)
echo "${project_root_path}"

cd ${build_dir}

rm -rf *

cmake	-DCMAKE_GENERATOR="Unix Makefiles"														\
		-DCMAKE_TOOLCHAIN_FILE=${project_root_path}/cmake_add/x86_64_linux.toolchain.cmake		\
		-DCMAKE_BUILD_TYPE=${build_type}														\
		${project_root_path}
make -j2

if [ "${build_type}" == "Debug" ];then
	exit
else
	echo "################################################## Make Build Target #################"
fi
