#!/usr/bin/env bash

set -eu -x -o pipefail

export OMP_NUM_THREADS=2
export TEST_DIR=examples/fodo

# is this a DP or SP build?
PRECISION=$($(which impactx.NOMPI.OMP.SP.OPMD >/dev/null) && echo "SINGLE" || echo "DOUBLE")

# executable
impactx.NOMPI.OMP.DP.OPMD ${TEST_DIR}/input_fodo.in

# Python
python ${TEST_DIR}/run_fodo.py

# Python: pytest
#   SP Space Charge not yet stable
#   https://github.com/BLAST-ImpactX/impactx/issues/1078
export SP_IGNORE=""
if [[ ${PRECISION} == "SINGLE" ]]; then
    export SP_IGNORE='-k "not (spacecharge or expanding or nC_)"'
fi
python -m pytest -s -vvvv ${SP_IGNORE} --ignore tests/python/dashboard tests/python/
