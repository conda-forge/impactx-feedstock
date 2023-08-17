#!/usr/bin/env bash

set -eu -x -o pipefail

export OMP_NUM_THREADS=2
export TEST_DIR=examples/fodo

# executable
impactx.NOMPI.OMP.DP.OPMD ${TEST_DIR}/input_fodo.in

# Python
$PYTHON ${TEST_DIR}/run_fodo.py

# macOS x86_64 pypy: import issue with matplotlib
#   AttributeError: module 'threading' has no attribute 'get_native_id'
# https://foss.heptapod.net/pypy/pypy/-/issues/3764
IS_PYPY=$(${PYTHON} -c "import platform; print(int(platform.python_implementation() == 'PyPy'))")
if [[ "${target_platform}" != "osx-64" ]] || [[ ${IS_PYPY} != "1" ]]; then
    $PYTHON -m pytest -s -vvvv tests/python/
fi
