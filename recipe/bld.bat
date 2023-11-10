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
    -DCMAKE_BUILD_TYPE=Release            ^
    -DCMAKE_C_COMPILER=clang-cl           ^
    -DCMAKE_CXX_COMPILER=clang-cl         ^
    -DCMAKE_INSTALL_LIBDIR=lib            ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PYTHONDIR=%SP_DIR%    ^
    -DCMAKE_LINKER=lld-link               ^
    -DCMAKE_NM=llvm-nm                    ^
    -DCMAKE_VERBOSE_MAKEFILE=ON           ^
    -DImpactX_amrex_internal=OFF          ^
    -DImpactX_openpmd_internal=OFF        ^
    -DImpactX_pyamrex_internal=OFF ^
    -DImpactX_pybind11_internal=OFF       ^
    -DImpactX_MPI=OFF       ^
    -DImpactX_OPENPMD=ON    ^
    -DImpactX_PYTHON=ON     ^
    -DPython_EXECUTABLE=%PYTHON%
if errorlevel 1 exit 1

:: build
cmake --build build --config Release --parallel 2
if errorlevel 1 exit 1
cmake --build build --config Release --parallel 2 --target pip_wheel
if errorlevel 1 exit 1

:: install
cmake --build build --config Release --target install
if errorlevel 1 exit 1
%PYTHON% -m pip install --force-reinstall --no-index --no-deps -vv --find-links=build\impactx-whl impactx
if errorlevel 1 exit 1

:: pytest -> deferred to test.sh
ctest --test-dir build --build-config Release --output-on-failure -E "(py|analysis|plot|pytest)"
if errorlevel 1 exit 1
