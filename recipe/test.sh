#!/usr/bin/env bash

set -eu -x -o pipefail

export OMP_NUM_THREADS=2
export TEST_DIR=examples/fodo

# executable
impactx.NOMPI.OMP.DP.OPMD ${TEST_DIR}/input_fodo.in

# Python
$PYTHON ${TEST_DIR}/run_fodo.py

# Python: pytest
$PYTHON -m pytest -s -vvvv tests/python/
