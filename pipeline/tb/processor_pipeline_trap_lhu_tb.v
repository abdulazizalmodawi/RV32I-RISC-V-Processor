`timescale 1ns / 1ps
module processor_pipeline_trap_lhu_tb;
  reg clk, rst;
  integer passed, failed;
  processor_pipeline_trap_top dut (.clk(clk), .rst(rst));
  task tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask
  task check;
    input condition;
    input [255:0] description;
    begin
      if (condition === 1'b1) begin
        passed = passed + 1;
        $display("PASS: %0s", description);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", description);
      end
    end
  endtask
  initial begin
    clk=0; rst=1; passed=0; failed=0;
    #2;
    // lhu x1, 1(x0): halfword address 1 is misaligned.
    dut.imem.memory[0] = 32'h00105083;
    dut.imem.memory[64] = 32'h00000013;
    repeat (2) tick();
    rst=0;
    repeat (7) tick();
    check(dut.trap_active === 1'b1, "LHU misalignment activates trap");
    check(dut.trap_mcause === 32'd4, "Load misalignment cause is 4");
    check(dut.trap_mepc === 32'd0, "Fault PC is zero");
    check(dut.trap_mtval === 32'd1, "Fault address is one");
    check(dut.rf.registers[1] === 32'd0, "No writeback to x1");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);
    if (passed == 5 && failed == 0)
      $display("ALL 5 LHU ALIGNMENT CHECKS PASSED");
    else
      $fatal(1, "LHU ALIGNMENT VERIFICATION FAILED");
    $finish;
  end
endmodule
