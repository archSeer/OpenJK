@REM Create OpenJK projects for Visual Studio 2012 using CMake
@echo off
for %%X in (cmake.exe) do (set FOUND=%%~$PATH:X)
if not defined FOUND (
	echo CMake was not found on your system. Please make sure you have installed CMake
	echo from http://www.cmake.org/ and cmake.exe is installed to your system's PATH
	echo environment variable.
	exit /b 1
) else (
	echo Found CMake!
)
if not exist build\nul (mkdir build)
pushd build
cmake -G "Visual Studio 11" -D CMAKE_INSTALL_PREFIX=../install ..
popd
pause