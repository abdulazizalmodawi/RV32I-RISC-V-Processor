
`timescale 1ns / 1ps

module processor_pipeline_trap_top_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;

  processor_pipeline_trap_top dut (
    .clk(clk),
    .rst(rst)
  );

  task tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  task check;
    input condition;
    input [255:0] name;
    begin
      if (condition === 1'b1) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", name);
      end
    end
  endtask

  initial begin
    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;

    // Allow instruction memory initialization
    #2;

    // Illegal instruction at address 0x00000000
    dut.imem.memory[0] = 32'hFFFFFFFF;

    // Safe instruction at trap vector 0x100
    dut.imem.memory[64] = 32'h00000013;

    // Reset processor
    repeat (2) tick();
    rst = 0;

    // Fetch illegal instruction
    tick();

    // Decode illegal instruction and take trap
    tick();

    $display("");
    $display("==============================");
    $display(" PIPELINE TRAP TEST");
    $display("==============================");

    check(dut.trap_active === 1'b1,
          "Trap becomes active");

    check(dut.pc === 32'h00000100,
          "PC redirects to trap vector");

    check(dut.trap_mepc === 32'h00000000,
          "MEPC saves faulting PC");

    check(dut.trap_mcause === 32'd2,
          "MCAUSE records illegal instruction");

    check(dut.trap_mtval === 32'hFFFFFFFF,
          "MTVAL saves illegal instruction");

    $display("------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 5 && failed == 0)
      $display("PIPELINE TRAP TEST PASSED");
    else
      $fatal(1, "PIPELINE TRAP TEST FAILED");

    $finish;
  end

endmodule
