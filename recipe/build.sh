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

# configure
cmake \
    -S ${SRC_DIR} -B build                \
    ${CMAKE_ARGS}                         \
    -DCMAKE_BUILD_TYPE=Release            \
    -DCMAKE_VERBOSE_MAKEFILE=ON           \
    -DCMAKE_INSTALL_LIBDIR=lib            \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}      \
    -DImpactX_COMPUTE=NOACC               \
    -DImpactX_IPO=${ImpactX_IPO}          \
    -DImpactX_openpmd_internal=OFF        \
    -DImpactX_pybind11_internal=OFF       \
    -DImpactX_LIB=ON      \
    -DImpactX_MPI=OFF     \
    -DImpactX_OPENPMD=ON  \
    -DImpactX_PYTHON=ON   \
    -DPython_EXECUTABLE=${PYTHON} \
    -DPython_INCLUDE_DIR=$(${PYTHON} -c "from sysconfig import get_paths as gp; print(gp()['include'])")

# build
cmake --build build --parallel ${CPU_COUNT}
cmake --build build --parallel ${CPU_COUNT} --target pyamrex_pip_wheel
cmake --build build --parallel ${CPU_COUNT} --target pip_wheel

# test
#  || "${CROSSCOMPILING_EMULATOR}" != ""
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
    # skip the pyAMReX tests to save CI time
    EXCLUSION_REGEX="AMReX"

    # macOS x86_64 pypy: import issue with matplotlib
    #   AttributeError: module 'threading' has no attribute 'get_native_id'
    # https://foss.heptapod.net/pypy/pypy/-/issues/3764
    if [[ "${target_platform}" == "osx-64" ]]; then
        IS_PYPY=$(${PYTHON} -c "import platform; print(int(platform.python_implementation() == 'PyPy'))")
        if [[ ${IS_PYPY} == "1" ]]; then
            EXCLUSION_REGEX="(AMReX|plot|pytest)"
        fi
    fi

    echo "EXCLUSION_REGEX=${EXCLUSION_REGEX}"
    ctest --test-dir build --output-on-failure -E "${EXCLUSION_REGEX}"
fi

# install
cmake --build build --target install
${PYTHON} -m pip install --force-reinstall --no-index --no-deps -vv --find-links=build/_deps/fetchedpyamrex-build/amrex-whl amrex
${PYTHON} -m pip install --force-reinstall --no-index --no-deps -vv --find-links=build/impactx-whl impactx
