set(CMAKE_SYSTEM_NAME QNX)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(QNX ON)
#set(arch ntox86_64)
#set(QNX_PROCESSOR x86_64)

set(arch ntoaarch64)
set(QNX_PROCESSOR aarch64)
set(CMAKE_SIZEOF_VOID_P 8)
set(AARCH64 ON)


set(CPP11  "-std=c++11")
add_definitions(-D__QNX__)
add_definitions(-D_QNX_SOURCE)
add_definitions(-D__unix__)
add_definitions(-D__qnx700__)


set(CMAKE_C_COMPILER $ENV{QNX_HOST}/usr/bin/${arch}-gcc)
set(CMAKE_C_COMPILER_TARGET ${arch})

set(CMAKE_CXX_COMPILER $ENV{QNX_HOST}/usr/bin/${arch}-g++)
set(CMAKE_CXX_COMPILER_TARGET ${arch})


set (CMAKE_STRIP $ENV{QNX_HOST}/usr/bin/${arch}-strip CACHE FILEPATH "Strip")
set (CMAKE_NM  $ENV{QNX_HOST}/usr/bin/${arch}-gcc-nm CACHE FILEPATH "NM")
set (CMAKE_RANLIB  $ENV{QNX_HOST}/usr/bin/${arch}-gcc-ranlib CACHE FILEPATH "Ranlib")
set (CMAKE_AR $ENV{QNX_HOST}/usr/bin/${arch}-gcc-ar CACHE FILEPATH "Archiver")

message(STATUS "---------CMAKE_STRIP = ${CMAKE_STRIP}")
message(STATUS "---------CMAKE_NM = ${CMAKE_NM}")
message(STATUS "---------CMAKE_RANLIB = ${CMAKE_RANLIB}")
message(STATUS "---------CMAKE_AR = ${CMAKE_AR}")
message(STATUS "---------CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
message(STATUS "---------CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}")

set(CMAKE_FIND_ROOT_PATH "...")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

#gcc and g++
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wl,--no-keep-memory -lm -march=armv8-a -DNDEBUG -fvisibility=hidden -Wno-unknown-pragmas -Wno-unused-function -Wno-strict-aliasing -O2 -ftree-vectorize -pipe -no-canonical-prefixes -fPIC" CACHE STRING "CMAKE_C_FLAGS")
#set(CMAKE_LDFLAGS = "${CMAKE_LD_FLAGS} -Wl,--no-keep-memory -lm -march=armv8-a -DNDEBUG -fvisibility=hidden -Wno-unknown-pragmas -Wno-unused-function -Wno-strict-aliasing -O2 -ftree-vectorize -pipe -no-canonical-prefixes -fPIC")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CPP11} -Wl,--no-keep-memory -lm -march=armv8-a -DNDEBUG -fpermissive -fvisibility=hidden -Wno-unknown-pragmas -Wno-unused-function -Wno-strict-aliasing -O2 -ftree-vectorize -pipe -no-canonical-prefixes -fPIC" CACHE STRING "CMAKE_CXX_FLAGS")


message(STATUS "---------QNX_TARGET = $ENV{QNX_TARGET}")
message(STATUS "---------INCLUDE_DIR_QNX = $ENV{QNX_TARGET}/usr/include")
include_directories($ENV{QNX_TARGET}/usr/include)


file(GLOB_RECURSE libgcc_a
  "$ENV{QNX_HOST}/usr/lib/gcc/${QNX_PROCESSOR}*/*/pic/libgcc.a")

set(CMAKE_C_STANDARD_LIBRARIES_INIT
  "${libgcc_a} -lc -Bstatic -lcS ${libgcc_a}")
set(CMAKE_CXX_STANDARD_LIBRARIES_INIT
  "-lc++ -lm ${CMAKE_C_STANDARD_LIBRARIES_INIT}")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-nodefaultlibs")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-nodefaultlibs")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-nodefaultlibs")

set(CMAKE_THREAD_LIBS_INIT "-lpthread")
set(CMAKE_HAVE_THREADS_LIBRARY 1)
set(CMAKE_USE_WIN32_THREADS_INIT 0)
set(CMAKE_USE_PTHREADS_INIT 1)
set(THREADS_PREFER_PTHREAD_FLAG ON)

set(output_dir  "${CMAKE_CURRENT_SOURCE_DIR}/output")
message(STATUS "AARACH64 QNX700 PLATFORM")
set (bin_dir "${output_dir}/bin/aarch64_qnx700")
set (lib_dir "${output_dir}/lib/aarch64_qnx700")

if(NOT DEFINED CMAKE_LIBRARY_OUTPUT_DIRECTORY)
	set (CMAKE_LIBRARY_OUTPUT_DIRECTORY "${bin_dir}")
	message(STATUS "############set CMAKE_LIBRARY_OUTPUT_DIRECTORY : ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} ")
endif()

if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
	set (CMAKE_RUNTIME_OUTPUT_DIRECTORY "${bin_dir}")
	message(STATUS "############set CMAKE_RUNTIME_OUTPUT_DIRECTORY : ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} ")
endif()

if(NOT DEFINED CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
	set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${lib_dir}")
	message(STATUS "############set CMAKE_ARCHIVE_OUTPUT_DIRECTORY : ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} ")
endif()
