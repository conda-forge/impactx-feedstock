#!/usr/bin/env bash

# avoid side-injection of -std=c++14 flag in some toolchains
if [[ ${CXXFLAGS} == *"-std=c++14"* ]]; then
    echo "14 -> 17"
    export CXXFLAGS="${CXXFLAGS} -std=c++17"
fi
# Darwin modern C++
#   https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
if [[ ${target_platform} =~ osx.* ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# IPO/LTO does only work with certain toolchains
ImpactX_IPO=ON
if [[ ${target_platform} =~ osx.* ]]; then
    ImpactX_IPO=OFF
fi

# Precision variants
if [[ ${impactx_precision} == "dp" ]]; then
    export PRECISION="DOUBLE"
    export ImpactX_FASTMATH=OFF
else
    export PRECISION="SINGLE"
    export ImpactX_FASTMATH=ON
fi

# configure
cmake \
    -S ${SRC_DIR} -B build                \
    ${CMAKE_ARGS}                         \
    -DCMAKE_BUILD_TYPE=Release            \
    -DCMAKE_VERBOSE_MAKEFILE=ON           \
    -DCMAKE_INSTALL_LIBDIR=lib            \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}      \
    -DImpactX_IPO=${ImpactX_IPO}          \
    -DImpactX_amrex_internal=OFF          \
    -DImpactX_openpmd_internal=OFF        \
    -DImpactX_pyamrex_internal=OFF        \
    -DImpactX_pybind11_internal=OFF       \
    -DImpactX_FASTMATH=${ImpactX_FASTMATH} \
    -DImpactX_FFT=ON      \
    -DImpactX_MPI=OFF     \
    -DImpactX_OPENPMD=ON  \
    -DImpactX_PRECISION=${PRECISION} \
    -DImpactX_PYTHON=ON   \
    -DImpactX_SIMD=ON     \
    -DPython_EXECUTABLE=${PYTHON} \
    -DPython_INCLUDE_DIR=$(${PYTHON} -c "from sysconfig import get_paths as gp; print(gp()['include'])")

# build
cmake --build build --parallel ${CPU_COUNT}

# pytest -> deferred to test.sh
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    if [[ ${impactx_precision} == "dp" ]]; then
        ctest --test-dir build --output-on-failure -E "(py|analysis|plot|pytest)"
    else
        # SP Space Charge not yet stable
        #   https://github.com/BLAST-ImpactX/impactx/issues/1078
        ctest --test-dir build --output-on-failure -E "(py|analysis|plot|pytest|spacecharge|expanding|nC_)"
    fi
fi

# install
cmake --build build --target install
cmake --build build --target pip_install_nodeps

#   do not install static libs from ABLASTR
rm -rf ${PREFIX}/lib/libablastr_*.a
#   do not install static libs from ImpactX
rm -rf ${PREFIX}/lib/libimpactx*.a
