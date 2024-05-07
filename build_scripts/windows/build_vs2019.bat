@echo off

set vs_bin_path="c:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe"
set build_type=Release

cd ../../

if exist cmake_build (rd /s /q cmake_build)
mkdir cmake_build
cd cmake_build

set cmake_build_dir=cmake_build_vs2019

if exist %cmake_build_dir% (rd /s /q %cmake_build_dir%)
mkdir %cmake_build_dir%
cd %cmake_build_dir%


cmake ..\..\  -G "Visual Studio 16 2019" -A x64 -DBUILD_BASE_UTILS_LIB_TEST=ON -DBUILD_WITH_EASY_PROFILER=ON


echo ################## Start Build Visual Studio Solution #################
%vs_bin_path% iCVBaseUtilsLib.sln /Build "%build_type%|x64" /Project ALL_BUILD /out ./Build.log
findstr ========== Build.log

pause
