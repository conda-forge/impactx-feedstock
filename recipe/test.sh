#!/usr/bin/env bash

set -eu -x -o pipefail

export OMP_NUM_THREADS=2
export TEST_DIR=examples/fodo

# is this a DP or SP build?
PRECISION=$($(which impactx.NOMPI.OMP.SP.OPMD >/dev/null) && echo "SINGLE" || echo "DOUBLE")

# executable
if [[ ${PRECISION} == "DOUBLE" ]]; then
    impactx.NOMPI.OMP.DP.OPMD ${TEST_DIR}/input_fodo.in
else
    impactx.NOMPI.OMP.SP.OPMD ${TEST_DIR}/input_fodo.in
fi

# Python
python ${TEST_DIR}/run_fodo.py

# Python: pytest
#   SP Space Charge not yet stable
#   https://github.com/BLAST-ImpactX/impactx/issues/1078
export TESTS_MATCH="not matchallyay"
if [[ ${PRECISION} == "SINGLE" ]]; then
    export TESTS_MATCH="not (spacecharge or expanding or nC_ or transformation or element_insert)"
fi
python -m pytest -s -vvvv -k "${TESTS_MATCH}" --ignore tests/python/dashboard tests/python/
