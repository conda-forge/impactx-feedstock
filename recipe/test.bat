@echo on

set "OMP_NUM_THREADS=2"
set "TEST_DIR=examples\fodo"

:: executable
impactx.NOMPI.OMP.DP.OPMD.exe %TEST_DIR%\input_fodo.in
if errorlevel 1 exit 1

:: Python
%PYTHON% %TEST_DIR%\run_fodo.py
if errorlevel 1 exit 1

%PYTHON% -m pytest -s -vvvv tests\python\
if errorlevel 1 exit 1
