`timescale 1ns / 1ps

module processor_alignment_tb;

  reg clk = 0;
  reg rst = 1;

  wire [31:0] pc;
  wire [31:0] instruction;
  wire execution_valid;

  integer passed = 0;
  integer failed = 0;

  processor_top dut (
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .instruction(instruction),
    .execution_valid(execution_valid)
  );

  always #5 clk = ~clk;

  task check;
    input [31:0] actual;
    input [31:0] expected;
    begin
      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: expected=%h actual=%h",
                 expected, actual);
      end else begin
        failed = failed + 1;
        $display("FAIL: expected=%h actual=%h",
                 expected, actual);
      end
    end
  endtask

  task reset_processor;
    begin
      @(negedge clk);
      rst = 1;
      @(posedge clk);
      #1;
      rst = 0;
    end
  endtask

  initial begin
    #1;
    $display("Starting instruction alignment test...");

    // =====================================
    // Test 1: Legal JAL (+8)
    // =====================================

    dut.imem.memory[0] = 32'h008002EF; // JAL x5,+8
    dut.imem.memory[1] = 32'h06300113; // ADDI x2,x0,99 (skip)
    dut.imem.memory[2] = 32'h00700193; // ADDI x3,x0,7
    dut.imem.memory[3] = 32'h0000006F; // JAL x0,0

    reset_processor();
    repeat (8) @(posedge clk);
    #1;

    check(dut.rf.registers[5], 32'd4);
    check(dut.rf.registers[2], 32'd0);
    check(dut.rf.registers[3], 32'd7);
    check(pc, 32'd12);
    check({31'd0,execution_valid},32'd1);

    // =====================================
    // Test 2: Illegal JAL (+6)
    // =====================================

    dut.imem.memory[0] = 32'h006002EF; // JAL x5,+6

    reset_processor();
    repeat (6) @(posedge clk);
    #1;

    check(pc, 32'd0);
    check(dut.rf.registers[5], 32'd0);
    check(dut.rf.registers[3], 32'd0);
    check({31'd0,execution_valid},32'd0);

    // =====================================
    // Test 3: Legal JALR
    // rs1 = 17, bit 0 cleared -> 16
    // =====================================

    dut.imem.memory[0] = 32'h01100093; // ADDI x1,x0,17
    dut.imem.memory[1] = 32'h000082E7; // JALR x5,0(x1)
    dut.imem.memory[2] = 32'h06300193; // ADDI x3,x0,99 (skip)
    dut.imem.memory[3] = 32'h06300213; // ADDI x4,x0,99 (skip)
    dut.imem.memory[4] = 32'h02A00313; // ADDI x6,x0,42
    dut.imem.memory[5] = 32'h0000006F; // JAL x0,0

    reset_processor();
    repeat (9) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd17);
    check(dut.rf.registers[5], 32'd8);
    check(dut.rf.registers[6], 32'd42);
    check(pc, 32'd20);
    check({31'd0,execution_valid},32'd1);

    // =====================================
    // Test 4: Illegal JALR target
    // rs1 = 18, target remains 18
    // =====================================

    dut.imem.memory[0] = 32'h01200093; // ADDI x1,x0,18

    reset_processor();
    repeat (6) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd18);
    check(dut.rf.registers[5], 32'd0);
    check(dut.rf.registers[6], 32'd0);
    check(pc, 32'd4);
    check({31'd0,execution_valid},32'd0);

    // =====================================
    // Test 5: Taken BEQ with bad target
    // Branch at PC=8, target=14
    // =====================================

    dut.imem.memory[0] = 32'h00000093; // ADDI x1,x0,0
    dut.imem.memory[1] = 32'h00000113; // ADDI x2,x0,0
    dut.imem.memory[2] = 32'h00208363; // BEQ x1,x2,+6
    dut.imem.memory[3] = 32'h00700193; // ADDI x3,x0,7

    reset_processor();
    repeat (7) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd0);
    check(dut.rf.registers[2], 32'd0);
    check(dut.rf.registers[3], 32'd0);
    check(pc, 32'd8);
    check({31'd0,execution_valid},32'd0);

    // =====================================
    // Test 6: Not-taken BEQ with bad target
    // Sequential execution must continue
    // =====================================

    dut.imem.memory[1] = 32'h00100113; // ADDI x2,x0,1
    dut.imem.memory[4] = 32'h0000006F; // JAL x0,0

    reset_processor();
    repeat (9) @(posedge clk);
    #1;

    check(dut.rf.registers[2], 32'd1);
    check(dut.rf.registers[3], 32'd7);
    check(pc, 32'd16);
    check({31'd0,execution_valid},32'd1);

    // =====================================
    // Final results
    // =====================================

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 28 && failed == 0)
      $display("INSTRUCTION ALIGNMENT TEST PASSED");
    else
      $fatal(1, "INSTRUCTION ALIGNMENT TEST FAILED");

    $finish;
  end

endmodule
