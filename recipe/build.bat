@echo on

:: simple install prep
::   copy all impactx*.exe and impactx*.dll files
if not exist %LIBRARY_PREFIX%\bin md %LIBRARY_PREFIX%\bin
if errorlevel 1 exit 1

:: Precision variants
if "%impactx_precision%" == "dp" (
    set "PRECISION=DOUBLE"
    set "ImpactX_FASTMATH=OFF"
) else (
    set "PRECISION=SINGLE"
    set "ImpactX_FASTMATH=ON"
)


:: configure
cmake ^
    -S %SRC_DIR% -B build                 ^
    %CMAKE_ARGS%                          ^
    -G "Ninja"                            ^
    -DCMAKE_BUILD_TYPE=Release            ^
    -DCMAKE_C_COMPILER=clang-cl           ^
    -DCMAKE_CXX_COMPILER=clang-cl         ^
    -DCMAKE_INSTALL_LIBDIR=%LIBRARY_PREFIX%/lib ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PYTHONDIR=%SP_DIR%    ^
    -DCMAKE_LINKER=lld-link               ^
    -DCMAKE_NM=llvm-nm                    ^
    -DCMAKE_VERBOSE_MAKEFILE=ON           ^
    -DImpactX_amrex_internal=OFF          ^
    -DImpactX_openpmd_internal=OFF        ^
    -DImpactX_pyamrex_internal=OFF        ^
    -DImpactX_pybind11_internal=OFF       ^
    -DImpactX_FASTMATH="%ImpactX_FASTMATH%" ^
    -DImpactX_FFT=ON        ^
    -DImpactX_MPI=OFF       ^
    -DImpactX_OPENPMD=ON    ^
    -DImpactX_PRECISION="%PRECISION%" ^
    -DImpactX_PYTHON=ON     ^
    -DImpactX_SIMD=ON       ^
    -DPython_EXECUTABLE=%PYTHON%
if errorlevel 1 exit 1

:: build
cmake --build build --config Release --parallel 2
if errorlevel 1 exit 1

:: install
cmake --build build --config Release --target install
if errorlevel 1 exit 1
cmake --build build --config Release --target pip_install_nodeps
if errorlevel 1 exit 1

::   do not install static libs from ABLASTR
del "%LIBRARY_PREFIX%\lib\ablastr_*.lib"
if errorlevel 1 exit 1
::   do not install static libs from ImpactX
del "%LIBRARY_PREFIX%\lib\libimpactx*.lib"
if errorlevel 1 exit 1

:: pytest -> deferred to test.sh
if "%impactx_precision%" == "dp" (
    ctest --test-dir build --build-config Release --output-on-failure -E "(py|analysis|plot|pytest)"
    if errorlevel 1 exit 1
) else (
    :: SP Space Charge not yet stable
    ::   https://github.com/BLAST-ImpactX/impactx/issues/1078
    ctest --test-dir build --build-config Release --output-on-failure -E "(py|analysis|plot|pytest|spacecharge|expanding|nC_)"
    if errorlevel 1 exit 1
)
