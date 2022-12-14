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
    -DImpactX_amrex_branch=13aa4df0f5a4af40270963ad5b42ac7ce662e045   ^
    -DImpactX_pyamrex_branch=526bcd72aff0f0147a261700b402fd0eebdb9fdb ^
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
%PYTHON% -m pip install --force-reinstall --no-index --no-deps -vv --find-links=build\_deps\fetchedpyamrex-build\amrex-whl amrex
if errorlevel 1 exit 1
%PYTHON% -m pip install --force-reinstall --no-index --no-deps -vv --find-links=build\impactx-whl impactx
if errorlevel 1 exit 1
