
@echo off
setlocal
cd /d "%~dp0"

echo ======================================
echo RV32I Pipeline - Automated Tests
echo ======================================

call :run if_id_reg_tb pipeline\if_id_reg.v pipeline\tb\if_id_reg_tb.v || goto failed
call :run id_ex_reg_tb pipeline\id_ex_reg.v pipeline\tb\id_ex_reg_tb.v || goto failed
call :run ex_mem_reg_tb pipeline\ex_mem_reg.v pipeline\tb\ex_mem_reg_tb.v || goto failed
call :run mem_wb_reg_tb pipeline\mem_wb_reg.v pipeline\tb\mem_wb_reg_tb.v || goto failed
call :run forwarding_unit_tb pipeline\forwarding_unit.v pipeline\tb\forwarding_unit_tb.v || goto failed
call :run hazard_detection_unit_tb pipeline\hazard_detection_unit.v pipeline\tb\hazard_detection_unit_tb.v || goto failed
call :run branch_flush_control_tb pipeline\branch_flush_control.v pipeline\tb\branch_flush_control_tb.v || goto failed
call :run if_id_valid_reg_tb pipeline\if_id_valid_reg.v pipeline\tb\if_id_valid_reg_tb.v || goto failed
call :run_pipeline_integration || goto failed
call :run_pipeline_hazards || goto failed
call :run_pipeline_memory_edge || goto failed
call :run_pipeline_safety || goto failed
call :run_pipeline_load_forward || goto failed
call :run_pipeline_stall_flush || goto failed
call :run exception_detection_unit_tb pipeline\exception_detection_unit.v pipeline\tb\exception_detection_unit_tb.v || goto failed
call :run trap_controller_tb pipeline\trap_controller.v pipeline\tb\trap_controller_tb.v || goto failed
call :run ex_mem_trap_reg_tb pipeline\ex_mem_trap_reg.v pipeline\tb\ex_mem_trap_reg_tb.v || goto failed

echo.
echo ======================================
echo ALL 17 PIPELINE TESTBENCHES PASSED
echo Pipeline and Independent Module Verification: 291 Checks
echo ======================================
pause
exit /b 0

:run
echo.
echo Running %1 ...
iverilog -g2012 -s %1 -o "%1.vvp" %2 %3
if errorlevel 1 exit /b 1
vvp "%1.vvp"
if errorlevel 1 exit /b 1
exit /b 0

:failed
echo.
echo TEST FAILED - Review output above.
pause
exit /b 1


:run_pipeline_integration
echo.
echo Running processor_pipeline_top_tb ...
iverilog -g2012 -s processor_pipeline_top_tb -o processor_pipeline_top_tb.vvp rtl\*.v pipeline\*.v pipeline\tb\processor_pipeline_top_tb.v
if errorlevel 1 exit /b 1
vvp processor_pipeline_top_tb.vvp
if errorlevel 1 exit /b 1
exit /b 0


:run_pipeline_hazards
echo.
echo Running processor_pipeline_hazards_tb ...
iverilog -g2012 -s processor_pipeline_hazards_tb -o processor_pipeline_hazards_tb.vvp rtl\*.v pipeline\*.v pipeline\tb\processor_pipeline_hazards_tb.v
if errorlevel 1 exit /b 1
vvp processor_pipeline_hazards_tb.vvp
if errorlevel 1 exit /b 1
exit /b 0


:run_pipeline_memory_edge
echo.
echo Running processor_pipeline_memory_edge_tb ...
iverilog -g2012 -s processor_pipeline_memory_edge_tb -o processor_pipeline_memory_edge_tb.vvp rtl\*.v pipeline\*.v pipeline\tb\processor_pipeline_memory_edge_tb.v
if errorlevel 1 exit /b 1
vvp processor_pipeline_memory_edge_tb.vvp
if errorlevel 1 exit /b 1
exit /b 0


:run_pipeline_safety
echo.
echo Running processor_pipeline_safety_tb ...
iverilog -g2012 -s processor_pipeline_safety_tb -o processor_pipeline_safety_tb.vvp rtl\*.v pipeline\*.v pipeline\tb\processor_pipeline_safety_tb.v
if errorlevel 1 exit /b 1
vvp processor_pipeline_safety_tb.vvp
if errorlevel 1 exit /b 1
exit /b 0


:run_pipeline_load_forward
echo.
echo Running pipeline_load_forward_diagnostic_tb ...
iverilog -g2012 -s pipeline_load_forward_diagnostic_tb -o pipeline_load_forward_diagnostic_tb.vvp rtl\*.v pipeline\*.v pipeline\tb\pipeline_load_forward_diagnostic_tb.v
if errorlevel 1 exit /b 1
vvp pipeline_load_forward_diagnostic_tb.vvp
if errorlevel 1 exit /b 1
exit /b 0


:run_pipeline_stall_flush
echo.
echo Running pipeline_stall_flush_diagnostic_tb ...
iverilog -g2012 -s pipeline_stall_flush_diagnostic_tb -o pipeline_stall_flush_diagnostic_tb.vvp rtl\*.v pipeline\*.v pipeline\tb\pipeline_stall_flush_diagnostic_tb.v
if errorlevel 1 exit /b 1
vvp pipeline_stall_flush_diagnostic_tb.vvp
if errorlevel 1 exit /b 1
exit /b 0
