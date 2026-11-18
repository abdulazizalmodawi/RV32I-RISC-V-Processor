
@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo RV32I RISC-V Processor Verification
echo Single-Cycle Automated Test Suite
echo ==========================================

echo.
echo [1/21] ALU
call :run alu_tb rtl\alu.v tb\alu_tb.v || goto failed

echo.
echo [2/21] ALU Control
call :run alu_control_tb rtl\alu_control.v tb\alu_control_tb.v || goto failed

echo.
echo [3/21] Branch Control
call :run branch_control_tb rtl\branch_control.v tb\branch_control_tb.v || goto failed

echo.
echo [4/21] Control Unit
call :run control_unit_tb rtl\control_unit.v tb\control_unit_tb.v || goto failed

echo.
echo [5/21] Data Memory
call :run data_memory_tb rtl\data_memory.v tb\data_memory_tb.v || goto failed

echo.
echo [6/21] Immediate Generator
call :run immediate_generator_tb rtl\immediate_generator.v tb\immediate_generator_tb.v || goto failed

echo.
echo [7/21] Instruction Memory
call :run instruction_memory_tb rtl\instruction_memory.v tb\instruction_memory_tb.v || goto failed

echo.
echo [8/21] Next PC Logic
call :run next_pc_logic_tb rtl\next_pc_logic.v tb\next_pc_logic_tb.v || goto failed

echo.
echo [9/21] Program Counter
call :run program_counter_tb rtl\program_counter.v tb\program_counter_tb.v || goto failed

echo.
echo [10/21] Register File
call :run register_file_tb rtl\register_file.v tb\register_file_tb.v || goto failed

echo.
echo ==========================================
echo Processor Integration Tests
echo ==========================================

echo.
echo [11/21] Basic Integration
call :run processor_top_tb rtl\*.v tb\processor_top_tb.v || goto failed

echo.
echo [12/21] Extended Integration
call :run processor_extended_tb rtl\*.v tb\processor_extended_tb.v || goto failed

echo.
echo [13/21] Memory and Branch
call :run processor_memory_branch_tb rtl\*.v tb\processor_memory_branch_tb.v || goto failed

echo.
echo [14/21] Arithmetic and Branch Loop
call :run processor_arithmetic_loop_tb rtl\*.v tb\processor_arithmetic_loop_tb.v || goto failed

echo.
echo [15/21] Instruction Alignment
call :run processor_alignment_tb rtl\*.v tb\processor_alignment_tb.v || goto failed

echo.
echo [16/21] Memory Encoding
call :run processor_memory_encoding_tb rtl\*.v tb\processor_memory_encoding_tb.v || goto failed

echo.
echo [17/21] Immediate Boundary
call :run processor_immediate_boundary_tb rtl\*.v tb\processor_immediate_boundary_tb.v || goto failed

echo.
echo [18/21] JALR Validation
call :run processor_jalr_validation_tb rtl\*.v tb\processor_jalr_validation_tb.v || goto failed

echo.
echo [19/21] Processor Safety
call :run processor_safety_tb rtl\*.v tb\processor_safety_tb.v || goto failed

echo.
echo [20/21] System Instructions
call :run processor_system_tb rtl\*.v tb\processor_system_tb.v || goto failed

echo.
echo [21/21] FENCE Validation
call :run processor_fence_tb rtl\*.v tb\processor_fence_tb.v || goto failed

echo.
echo ==========================================
echo ALL 21 TESTBENCHES PASSED
echo Single-Cycle Verification: 373 Checks
echo ==========================================
pause
exit /b 0

:run
echo Compiling %1 ...
iverilog -g2012 -s %1 -o "%1.vvp" %2 %3
if errorlevel 1 exit /b 1

echo Running %1 ...
vvp "%1.vvp"
if errorlevel 1 exit /b 1

exit /b 0

:failed
echo.
echo ==========================================
echo TEST FAILED - Review output above
echo ==========================================
pause
exit /b 1
