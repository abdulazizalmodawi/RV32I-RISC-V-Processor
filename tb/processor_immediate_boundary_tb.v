`timescale 1ns / 1ps
module processor_immediate_boundary_tb;

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

    // I-Type boundary values and sign extension
    dut.imem.memory[0]  = 32'h80000093; // ADDI x1,x0,-2048
    dut.imem.memory[1]  = 32'h7FF00113; // ADDI x2,x0,2047
    dut.imem.memory[2]  = 32'h7FF08193; // ADDI x3,x1,2047
    dut.imem.memory[3]  = 32'h80010213; // ADDI x4,x2,-2048
    dut.imem.memory[4]  = 32'h8010A293; // SLTI x5,x1,-2047
    dut.imem.memory[5]  = 32'hFFF0B313; // SLTIU x6,x1,-1
    dut.imem.memory[6]  = 32'hFFF0C393; // XORI x7,x1,-1
    dut.imem.memory[7]  = 32'hFFF17413; // ANDI x8,x2,-1
    dut.imem.memory[8]  = 32'h80006493; // ORI x9,x0,-2048

    // U-Type boundary values
    dut.imem.memory[9]  = 32'h80000537; // LUI x10,0x80000
    dut.imem.memory[10] = 32'hFFFFF597; // AUIPC x11,0xFFFFF

    // Negative branch offset and loop
    dut.imem.memory[11] = 32'h00300613; // ADDI x12,x0,3
    dut.imem.memory[12] = 32'hFFF60613; // ADDI x12,x12,-1
    dut.imem.memory[13] = 32'hFE061EE3; // BNE x12,x0,-4

    // Forward jump
    dut.imem.memory[14] = 32'h04D00693; // ADDI x13,x0,77
    dut.imem.memory[15] = 32'h0080076F; // JAL x14,+8
    dut.imem.memory[16] = 32'h06300793; // Skipped
    dut.imem.memory[17] = 32'hFFF00813; // ADDI x16,x0,-1
    dut.imem.memory[18] = 32'h0000006F; // JAL x0,0

    $display("Starting immediate boundary test...");

    @(negedge clk);
    rst = 0;

    repeat (40) @(posedge clk);
    #1;

    check(dut.rf.registers[0],  32'd0);
    check(dut.rf.registers[1],  32'hFFFFF800);
    check(dut.rf.registers[2],  32'd2047);
    check(dut.rf.registers[3],  32'hFFFFFFFF);
    check(dut.rf.registers[4],  32'hFFFFFFFF);
    check(dut.rf.registers[5],  32'd1);
    check(dut.rf.registers[6],  32'd1);
    check(dut.rf.registers[7],  32'h000007FF);
    check(dut.rf.registers[8],  32'h000007FF);
    check(dut.rf.registers[9],  32'hFFFFF800);
    check(dut.rf.registers[10], 32'h80000000);
    check(dut.rf.registers[11], 32'hFFFFF028);
    check(dut.rf.registers[12], 32'd0);
    check(dut.rf.registers[13], 32'd77);
    check(dut.rf.registers[14], 32'd64);
    check(dut.rf.registers[15], 32'd0);
    check(dut.rf.registers[16], 32'hFFFFFFFF);
    check(pc, 32'd72);
    check(instruction, 32'h0000006F);
    check({31'd0, execution_valid}, 32'd1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 20 && failed == 0)
      $display("IMMEDIATE BOUNDARY TEST PASSED");
    else
      $fatal(1, "IMMEDIATE BOUNDARY TEST FAILED");

    $finish;
  end

endmodule
