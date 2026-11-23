
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

    #2;

    // =========================================
    // TEST 1: ILLEGAL INSTRUCTION
    // =========================================

    dut.imem.memory[0] = 32'hFFFFFFFF;
    dut.imem.memory[64] = 32'h00000013;

    repeat (2) tick();
    rst = 0;

    // Allow illegal instruction to reach ID
    repeat (2) tick();

    $display("");
    $display("TEST 1: ILLEGAL INSTRUCTION");

    check(dut.trap_active === 1'b1,
          "Illegal instruction trap active");

    check(dut.pc === 32'h00000100,
          "Illegal instruction redirect");

    check(dut.trap_mepc === 32'd0,
          "Illegal instruction MEPC");

    check(dut.trap_mcause === 32'd2,
          "Illegal instruction MCAUSE");

    check(dut.trap_mtval === 32'hFFFFFFFF,
          "Illegal instruction MTVAL");


    // =========================================
    // TEST 2: MISALIGNED LOAD
    // =========================================

    rst = 1;

    // lw x1, 1(x0)
    dut.imem.memory[0] = 32'h00102083;

    repeat (2) tick();
    rst = 0;

    // Allow LOAD to reach MEM
    repeat (7) tick();

    $display("");
    $display("TEST 2: MISALIGNED LOAD");

    check(dut.trap_active === 1'b1,
          "Misaligned load trap active");

    check(dut.trap_mcause === 32'd4,
          "Misaligned load MCAUSE");

    check(dut.trap_mepc === 32'd0,
          "Misaligned load MEPC");

    check(dut.trap_mtval === 32'd1,
          "Misaligned load MTVAL");

    check(dut.rf.registers[1] === 32'd0,
          "Misaligned load blocks writeback");


    // =========================================
    // TEST 3: MISALIGNED STORE
    // =========================================

    rst = 1;

    // sw x2, 1(x0)
    dut.imem.memory[0] = 32'h002020A3;

    repeat (2) tick();

    // Initialize memory with a known value
    // A misaligned store must not overwrite it.
    dut.dmem.memory[1] = 8'hA5;
    dut.dmem.memory[2] = 8'h5A;
    dut.dmem.memory[3] = 8'hC3;
    dut.dmem.memory[4] = 8'h3C;

    rst = 0;

    // Allow STORE to reach MEM
    repeat (7) tick();

    $display("");
    $display("TEST 3: MISALIGNED STORE");

    check(dut.trap_active === 1'b1,
          "Misaligned store trap active");

    check(dut.trap_mcause === 32'd6,
          "Misaligned store MCAUSE");

    check(dut.trap_mepc === 32'd0,
          "Misaligned store MEPC");

    check(dut.trap_mtval === 32'd1,
          "Misaligned store MTVAL");

    check(
      dut.dmem.memory[1] === 8'hA5 &&
      dut.dmem.memory[2] === 8'h5A &&
      dut.dmem.memory[3] === 8'hC3 &&
      dut.dmem.memory[4] === 8'h3C,
      "Misaligned store preserves memory"
    );

 
    // =========================================
    // TEST 4: MISALIGNED JUMP TARGET
    // =========================================

    rst = 1;

    // jal x0, 2
    // Target address 0x00000002 is misaligned
    dut.imem.memory[0] = 32'h0020006F;

    // Wrong-path instruction
    // addi x3, x0, 99
    dut.imem.memory[1] = 32'h06300193;

    // Safe instruction at trap vector
    dut.imem.memory[64] = 32'h00000013;

    repeat (2) tick();
    rst = 0;

    // Allow jump to reach EX stage
    repeat (6) tick();

    $display("");
    $display("TEST 4: MISALIGNED JUMP TARGET");

    check(dut.trap_active === 1'b1,
          "Misaligned jump activates trap");

    check(dut.trap_mcause === 32'd0,
          "MCAUSE records instruction misalignment");

    check(dut.trap_mepc === 32'd0,
          "MEPC saves jump instruction PC");

    check(dut.trap_mtval === 32'd2,
          "MTVAL saves misaligned jump target");

    check(dut.rf.registers[3] === 32'd0,
          "Wrong-path instruction is flushed");
 

    // =========================================
    // FINAL RESULTS
    // =========================================

    $display("");
    $display("==================================");
    $display(" PIPELINE TRAP VERIFICATION");
    $display("==================================");

    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);


    if (passed == 20 && failed == 0)
      $display("ALL 20 PIPELINE TRAP CHECKS PASSED");
    else
      $fatal(1, "PIPELINE TRAP VERIFICATION FAILED");

    $finish;
  end

endmodule
