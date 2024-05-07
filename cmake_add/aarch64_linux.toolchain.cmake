set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(AARCH64 ON)
# set (PREFIX "/usr/local/bin/gcc-5.5.0/bin/aarch64-unknown-linux-gnu-")
#set (PREFIX "/opt/hisi-linux/x86-arm/aarch64-himix100-linux/bin/aarch64-himix100-linux-")
# 172.20.191.53
set (PREFIX "/data/wensha2/tool/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-")
set (CMAKE_STRIP ${PREFIX}strip CACHE FILEPATH "Strip")
set (CMAKE_NM  ${PREFIX}gcc-nm CACHE FILEPATH "NM")
set (CMAKE_RANLIB  ${PREFIX}gcc-ranlib CACHE FILEPATH "Ranlib")
set (CMAKE_AR ${PREFIX}gcc-ar CACHE FILEPATH "Archiver")
set (CMAKE_C_COMPILER ${PREFIX}gcc CACHE FILEPATH "GCC")
set (CMAKE_CXX_COMPILER ${PREFIX}g++ CACHE FILEPATH "G++")
#set (CMAKE_GCC_VERSION 10 CACHE STRING "" FORCE)

message(STATUS "---------CMAKE_STRIP = ${CMAKE_STRIP}")
message(STATUS "---------CMAKE_NM = ${CMAKE_NM}")
message(STATUS "---------CMAKE_RANLIB = ${CMAKE_RANLIB}")
message(STATUS "---------CMAKE_AR = ${CMAKE_AR}")
message(STATUS "---------CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
message(STATUS "---------CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}")
#message(STATUS "---------CMAKE_GCC_VERSION = ${CMAKE_GCC_VERSION}")

set(CMAKE_FIND_ROOT_PATH "...")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

add_definitions(-D__aarch64__)
add_definitions(-D__ARM_NEON__)

set(CPP11  "-std=c++11")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread -fvisibility=hidden -fPIC -O2 -ftree-vectorize -pipe -no-canonical-prefixes -march=armv8-a")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CPP11} -pthread -fpermissive -fvisibility=hidden -fPIC -O2 -ftree-vectorize -pipe -no-canonical-prefixes -march=armv8-a")

set(output_dir  "${CMAKE_CURRENT_SOURCE_DIR}/output")
set (bin_dir "${output_dir}/bin/aarch64_linux")
set (lib_dir "${output_dir}/lib/aarch64_linux")

if(NOT DEFINED CMAKE_LIBRARY_OUTPUT_DIRECTORY)
	set (CMAKE_LIBRARY_OUTPUT_DIRECTORY "${bin_dir}" CACHE STRING "" FORCE)
	message(STATUS "############set CMAKE_LIBRARY_OUTPUT_DIRECTORY : ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} ")
endif()

if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
	set (CMAKE_RUNTIME_OUTPUT_DIRECTORY "${bin_dir}" CACHE STRING "" FORCE)
	message(STATUS "############set CMAKE_RUNTIME_OUTPUT_DIRECTORY : ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} ")
endif()

if(NOT DEFINED CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
	set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${lib_dir}" CACHE STRING "" FORCE)
	message(STATUS "############set CMAKE_ARCHIVE_OUTPUT_DIRECTORY : ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} ")
endif()
