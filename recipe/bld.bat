@echo on

:: simple install prep
::   copy all impactx*.exe and impactx*.dll files
if not exist %LIBRARY_PREFIX%\bin md %LIBRARY_PREFIX%\bin
if errorlevel 1 exit 1

:: configure
cmake ^
    -S %SRC_DIR% -B build                 ^
    %CMAKE_ARGS%                          ^
    -G "Ninja"                            ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo     ^
    -DCMAKE_C_COMPILER=clang-cl           ^
    -DCMAKE_CXX_COMPILER=clang-cl         ^
    -DCMAKE_LINKER=lld-link               ^
    -DCMAKE_NM=llvm-nm                    ^
    -DCMAKE_VERBOSE_MAKEFILE=ON           ^
    -DImpactX_amrex_branch=35ed6b4d343215c1ccf6e4d0a59813fc236c9f22   ^
    -DImpactX_pyamrex_branch=1f88c1bf5731bfb15f1ee22ced79904a4776442b ^
    -DImpactX_pybind11_internal=OFF       ^
    -DImpactX_COMPUTE=NOACC ^
    -DImpactX_LIB=ON        ^
    -DImpactX_MPI=OFF       ^
    -DImpactX_PYTHON=ON     ^
    -DPython_EXECUTABLE=%PYTHON%
if errorlevel 1 exit 1

:: build
cmake --build build --config RelWithDebInfo --parallel 2
if errorlevel 1 exit 1
cmake --build build --config RelWithDebInfo --parallel 2 --target pyamrex_pip_wheel
if errorlevel 1 exit 1
cmake --build build --config RelWithDebInfo --parallel 2 --target pip_wheel
if errorlevel 1 exit 1

:: test
ctest --test-dir build --build-config RelWithDebInfo --output-on-failure -E pytest
if errorlevel 1 exit 1

:: install
cmake --build build --config RelWithDebInfo --target install
if errorlevel 1 exit 1
cmake --build build --config RelWithDebInfo --target pip_install
if errorlevel 1 exit 1
