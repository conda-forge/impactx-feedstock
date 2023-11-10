@echo on

set "OMP_NUM_THREADS=2"
set "TEST_DIR=examples\fodo"

:: executable
impactx.NOMPI.OMP.DP.OPMD.exe %TEST_DIR%\input_fodo.in
if errorlevel 1 exit 1

:: Python
%PYTHON% %TEST_DIR%\run_fodo.py
if errorlevel 1 exit 1

:: work-around for Matplotlib bug in savefig to png in Agg
:: backend
:: https://github.com/conda-forge/impactx-feedstock/pull/23#issuecomment-1805199294
set "MPLBACKEND=TkAgg"

:: Python: pytest
%PYTHON% -m pytest -s -vvvv tests\python\
if errorlevel 1 exit 1
