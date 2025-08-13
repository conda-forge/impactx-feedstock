@echo on

set "OMP_NUM_THREADS=2"
set "TEST_DIR=examples\fodo"

:: is this a DP or SP build?
where /q impactx.NOMPI.OMP.SP.OPMD.exe && set "PRECISION=SINGLE" || set "PRECISION=DOUBLE"

:: executable
impactx.NOMPI.OMP.DP.OPMD.exe %TEST_DIR%\input_fodo.in
if errorlevel 1 exit 1

:: Python
python %TEST_DIR%\run_fodo.py
if errorlevel 1 exit 1

:: Python: pytest
::   Skip tests for Matplotlib bug in savefig to png in Agg backend
::     https://github.com/conda-forge/impactx-feedstock/pull/23#issuecomment-1805199294
set "IGNORE_TESTS=not (test_charge_deposition or test_df_pandas or test_wake)"
::   SP Space Charge not yet stable
::     https://github.com/BLAST-ImpactX/impactx/issues/1078
if "%PRECISION%" == "DOUBLE" (
    set "IGNORE_TESTS=not (test_charge_deposition or test_df_pandas or test_wake or spacecharge or expanding or nC_)"
)
python -m pytest -s -vvvv -k "%IGNORE_TESTS%" --ignore tests\python\dashboard tests\python\
if errorlevel 1 exit 1
