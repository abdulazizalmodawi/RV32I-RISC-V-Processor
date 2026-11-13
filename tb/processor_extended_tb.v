`timescale 1ns / 1ps

module processor_extended_tb;

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

    // Extended RV32I test program
    dut.imem.memory[0]  = 32'hFFF00093; // ADDI x1,x0,-1
    dut.imem.memory[1]  = 32'h00100113; // ADDI x2,x0,1
    dut.imem.memory[2]  = 32'h0020A1B3; // SLT x3,x1,x2
    dut.imem.memory[3]  = 32'h0020B233; // SLTU x4,x1,x2
    dut.imem.memory[4]  = 32'h00F0F293; // ANDI x5,x1,15
    dut.imem.memory[5]  = 32'h05506313; // ORI x6,x0,85
    dut.imem.memory[6]  = 32'h00F34393; // XORI x7,x6,15
    dut.imem.memory[7]  = 32'h00411413; // SLLI x8,x2,4
    dut.imem.memory[8]  = 32'h00245493; // SRLI x9,x8,2
    dut.imem.memory[9]  = 32'h4030D513; // SRAI x10,x1,3

    dut.imem.memory[10] = 32'h123455B7; // LUI x11,0x12345
    dut.imem.memory[11] = 32'h00000617; // AUIPC x12,0
    dut.imem.memory[12] = 32'h00700423; // SB x7,8(x0)
    dut.imem.memory[13] = 32'h00804683; // LBU x13,8(x0)
    dut.imem.memory[14] = 32'h00800703; // LB x14,8(x0)

    dut.imem.memory[15] = 32'h00419463; // BNE x3,x4,+8
    dut.imem.memory[16] = 32'h06300793; // ADDI x15,x0,99 (skip)
    dut.imem.memory[17] = 32'h04C00813; // ADDI x16,x0,76
    dut.imem.memory[18] = 32'h001808E7; // JALR x17,x16,1
    dut.imem.memory[19] = 32'h02A00913; // ADDI x18,x0,42
    dut.imem.memory[20] = 32'h0000006F; // JAL x0,0 (loop)

    $display("Starting extended processor integration test...");

    // Release reset
    @(negedge clk);
    rst = 0;

    // Allow the complete test program to execute
    repeat (25) @(posedge clk);
    #1;

    // Arithmetic, logical, and shift results
    check(dut.rf.registers[1],  32'hFFFFFFFF);
    check(dut.rf.registers[2],  32'd1);
    check(dut.rf.registers[3],  32'd1);
    check(dut.rf.registers[4],  32'd0);
    check(dut.rf.registers[5],  32'd15);
    check(dut.rf.registers[6],  32'd85);
    check(dut.rf.registers[7],  32'd90);
    check(dut.rf.registers[8],  32'd16);
    check(dut.rf.registers[9],  32'd4);
    check(dut.rf.registers[10], 32'hFFFFFFFF);

    // Upper immediate and PC-relative result
    check(dut.rf.registers[11], 32'h12345000);
    check(dut.rf.registers[12], 32'd44);

    // Byte load results
    check(dut.rf.registers[13], 32'd90);
    check(dut.rf.registers[14], 32'd90);

    // Branch and jump behavior
    check(dut.rf.registers[15], 32'd0);
    check(dut.rf.registers[16], 32'd76);
    check(dut.rf.registers[17], 32'd76);
    check(dut.rf.registers[18], 32'd42);

    // Data memory stores the expected byte
    check({24'd0, dut.dmem.memory[8]}, 32'h0000005A);

    // Program reached the final JAL loop
    check(pc, 32'd80);
    check({31'd0, execution_valid}, 32'd1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 21 && failed == 0)
      $display("EXTENDED PROCESSOR TEST PASSED");
    else
      $fatal(1, "EXTENDED PROCESSOR TEST FAILED");

    $finish;
  end

endmodule
