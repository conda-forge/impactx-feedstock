@echo on

set "OMP_NUM_THREADS=2"
set "TEST_DIR=examples\fodo"

:: is this a DP or SP build?
where /q impactx.NOMPI.OMP.SP.OPMD.exe && set "PRECISION=SINGLE" || set "PRECISION=DOUBLE"

:: executable
if "%PRECISION%" == "DOUBLE" (
    impactx.NOMPI.OMP.DP.OPMD.exe %TEST_DIR%\input_fodo.in
    if errorlevel 1 exit 1
) else (
    impactx.NOMPI.OMP.SP.OPMD.exe %TEST_DIR%\input_fodo.in
    if errorlevel 1 exit 1
)

:: Python
python %TEST_DIR%\run_fodo.py
if errorlevel 1 exit 1

:: Python: pytest
::   Skip tests for Matplotlib bug in savefig to png in Agg backend
::     https://github.com/conda-forge/impactx-feedstock/pull/23#issuecomment-1805199294
set "TESTS_MATCH=not (test_charge_deposition or test_df_pandas or test_wake)"
::   SP Space Charge not yet stable
::     https://github.com/BLAST-ImpactX/impactx/issues/1078
if "%PRECISION%" == "SINGLE" (
    set "TESTS_MATCH=not (test_charge_deposition or test_df_pandas or test_wake or spacecharge or expanding or nC_ or transformation or element_insert)"
)
python -m pytest -s -vvvv -k "%TESTS_MATCH%" --ignore tests\python\dashboard tests\python\
if errorlevel 1 exit 1
