
`timescale 1ns / 1ps

module processor_pipeline_trap_priority_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;

  reg saw_mem_priority;
  reg saw_ex_priority;

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

  // Observe actual simultaneous exceptions
  // before the pipeline clock update.
  always @(posedge clk) begin
    if (rst) begin
      saw_mem_priority <= 1'b0;
      saw_ex_priority <= 1'b0;
    end else begin

      if (dut.mem_valid &&
          dut.mem_mem_read &&
          dut.mem_address_misaligned &&
          dut.ex_valid &&
          dut.ex_control_transfer &&
          !dut.ex_target_valid &&
          dut.id_valid &&
          dut.id_illegal_instruction &&
          dut.exception_valid &&
          dut.exception_stage == 2'b11)
        saw_mem_priority <= 1'b1;

      if (dut.ex_valid &&
          dut.ex_control_transfer &&
          !dut.ex_target_valid &&
          dut.id_valid &&
          dut.id_illegal_instruction &&
          dut.exception_valid &&
          dut.exception_stage == 2'b10)
        saw_ex_priority <= 1'b1;

    end
  end

  initial begin
    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;
    saw_mem_priority = 0;
    saw_ex_priority = 0;

    #2;

    // =========================================
    // TEST 1: MEM > EX > ID
    // =========================================

    // MEM: lw x1, 1(x0)
    // Misaligned load
    dut.imem.memory[0] = 32'h00102083;

    // EX: jal x0, 2
    // Misaligned instruction target
    dut.imem.memory[1] = 32'h0020006F;

    // ID: Illegal instruction
    dut.imem.memory[2] = 32'hFFFFFFFF;

    // Younger instruction must not execute
    dut.imem.memory[3] = 32'h06300193;

    // Trap handler: NOP
    dut.imem.memory[64] = 32'h00000013;

    repeat (2) tick();
    rst = 0;

    repeat (8) tick();

    $display("");
    $display("TEST 1: MEM > EX > ID");

    check(saw_mem_priority,
          "MEM wins simultaneous exceptions");

    check(dut.trap_active === 1'b1,
          "MEM priority trap active");

    check(dut.trap_mcause === 32'd4,
          "MEM load exception cause");

    check(dut.trap_mepc === 32'd0,
          "MEM faulting instruction PC");

    check(dut.trap_mtval === 32'd1,
          "MEM faulting memory address");

    check(dut.rf.registers[3] === 32'd0,
          "Younger instruction not committed");


    // =========================================
    // TEST 2: EX > ID
    // =========================================

    rst = 1;

    // EX: jal x0, 2
    dut.imem.memory[0] = 32'h0020006F;

    // ID: Illegal instruction
    dut.imem.memory[1] = 32'hFFFFFFFF;

    // Younger instruction
    dut.imem.memory[2] = 32'h06300193;

    // Trap handler: NOP
    dut.imem.memory[64] = 32'h00000013;

    repeat (2) tick();
    rst = 0;

    repeat (7) tick();

    $display("");
    $display("TEST 2: EX > ID");

    check(saw_ex_priority,
          "EX wins over ID exception");

    check(dut.trap_active === 1'b1,
          "EX priority trap active");

    check(dut.trap_mcause === 32'd0,
          "EX misaligned target cause");

    check(dut.trap_mepc === 32'd0,
          "EX faulting jump PC");

    check(dut.trap_mtval === 32'd2,
          "EX misaligned target address");

    check(dut.rf.registers[3] === 32'd0,
          "Younger instruction flushed");


    // =========================================
    // FINAL RESULTS
    // =========================================

    $display("");
    $display("==================================");
    $display(" PIPELINE EXCEPTION PRIORITY TEST");
    $display("==================================");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 12 && failed == 0)
      $display("ALL 12 PRIORITY CHECKS PASSED");
    else
      $fatal(1, "EXCEPTION PRIORITY TEST FAILED");

    $finish;
  end

endmodule
