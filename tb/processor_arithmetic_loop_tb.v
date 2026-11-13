`timescale 1ns / 1ps

module processor_arithmetic_loop_tb;

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

  initial begin
    #1;

    // Arithmetic, logic, and branch loop program
    dut.imem.memory[0]  = 32'hFF000093; // ADDI x1,x0,-16
    dut.imem.memory[1]  = 32'h00300113; // ADDI x2,x0,3
    dut.imem.memory[2]  = 32'h00100193; // ADDI x3,x0,1
    dut.imem.memory[3]  = 32'h00208233; // ADD x4,x1,x2
    dut.imem.memory[4]  = 32'h403102B3; // SUB x5,x2,x3
    dut.imem.memory[5]  = 32'h0020F333; // AND x6,x1,x2
    dut.imem.memory[6]  = 32'h0020E3B3; // OR x7,x1,x2
    dut.imem.memory[7]  = 32'h0020C433; // XOR x8,x1,x2
    dut.imem.memory[8]  = 32'h002194B3; // SLL x9,x3,x2
    dut.imem.memory[9]  = 32'h0020D533; // SRL x10,x1,x2
    dut.imem.memory[10] = 32'h4020D5B3; // SRA x11,x1,x2
    dut.imem.memory[11] = 32'h0020A633; // SLT x12,x1,x2
    dut.imem.memory[12] = 32'h0020B6B3; // SLTU x13,x1,x2
    dut.imem.memory[13] = 32'hFF10A713; // SLTI x14,x1,-15
    dut.imem.memory[14] = 32'hFFF13793; // SLTIU x15,x2,-1
    dut.imem.memory[15] = 32'h00200813; // ADDI x16,x0,2
    dut.imem.memory[16] = 32'h410808B3; // SUB x17,x16,x16

    // Forward BEQ skips instruction 18
    dut.imem.memory[17] = 32'h00088463; // BEQ x17,x0,+8
    dut.imem.memory[18] = 32'h06300913; // ADDI x18,x0,99
    dut.imem.memory[19] = 32'h02A00993; // ADDI x19,x0,42

    // Countdown loop using backward BNE
    dut.imem.memory[20] = 32'h00300A13; // ADDI x20,x0,3
    dut.imem.memory[21] = 32'hFFFA0A13; // ADDI x20,x20,-1
    dut.imem.memory[22] = 32'hFE0A1EE3; // BNE x20,x0,-4
    dut.imem.memory[23] = 32'h04D00A93; // ADDI x21,x0,77
    dut.imem.memory[24] = 32'h0000006F; // JAL x0,0

    $display("Starting arithmetic and branch loop test...");

    @(negedge clk);
    rst = 0;

    repeat (40) @(posedge clk);
    #1;

    // Check architectural register results
    check(dut.rf.registers[0],  32'd0);
    check(dut.rf.registers[1],  32'hFFFFFFF0);
    check(dut.rf.registers[2],  32'd3);
    check(dut.rf.registers[3],  32'd1);
    check(dut.rf.registers[4],  32'hFFFFFFF3);
    check(dut.rf.registers[5],  32'd2);
    check(dut.rf.registers[6],  32'd0);
    check(dut.rf.registers[7],  32'hFFFFFFF3);
    check(dut.rf.registers[8],  32'hFFFFFFF3);
    check(dut.rf.registers[9],  32'd8);
    check(dut.rf.registers[10], 32'h1FFFFFFE);
    check(dut.rf.registers[11], 32'hFFFFFFFE);
    check(dut.rf.registers[12], 32'd1);
    check(dut.rf.registers[13], 32'd0);
    check(dut.rf.registers[14], 32'd1);
    check(dut.rf.registers[15], 32'd1);
    check(dut.rf.registers[16], 32'd2);
    check(dut.rf.registers[17], 32'd0);
    check(dut.rf.registers[18], 32'd0);
    check(dut.rf.registers[19], 32'd42);
    check(dut.rf.registers[20], 32'd0);
    check(dut.rf.registers[21], 32'd77);

    // Final program loop at address 96
    check(pc, 32'd96);
    check({31'd0, execution_valid}, 32'd1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 24 && failed == 0)
      $display("ARITHMETIC AND BRANCH LOOP TEST PASSED");
    else
      $fatal(1, "ARITHMETIC AND BRANCH LOOP TEST FAILED");

    $finish;
  end

endmodule
