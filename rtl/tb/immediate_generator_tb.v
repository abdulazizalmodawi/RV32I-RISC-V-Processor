`timescale 1ns / 1ps

module immediate_generator_tb;

  reg [31:0] instruction;
  wire [31:0] immediate;

  integer passed = 0;
  integer failed = 0;

  immediate_generator dut (
    .instruction(instruction),
    .immediate(immediate)
  );

  task check;
    input [31:0] test_instruction;
    input [31:0] expected;
    begin
      instruction = test_instruction;
      #10;

      if (immediate === expected) begin
        passed = passed + 1;
        $display("PASS: instr=%h immediate=%h",
                 instruction, immediate);
      end else begin
        failed = failed + 1;
        $display("FAIL: instr=%h expected=%h actual=%h",
                 instruction, expected, immediate);
      end
    end
  endtask

  initial begin
    $display("Starting Immediate Generator verification...");

    // I-Type: ADDI
    check(32'h00000013, 32'h00000000);
    check(32'h00100013, 32'h00000001);
    check(32'h7FF00013, 32'h000007FF);
    check(32'hFFF00013, 32'hFFFFFFFF);
    check(32'h80000013, 32'hFFFFF800);

    // I-Type: LOAD and JALR
    check(32'hFF000003, 32'hFFFFFFF0);
    check(32'h07B00067, 32'h0000007B);

    // S-Type: STORE
    check(32'h00000023, 32'h00000000);
    check(32'h120001A3, 32'h00000123);
    check(32'hFE000FA3, 32'hFFFFFFFF);
    check(32'h80000023, 32'hFFFFF800);

    // B-Type: BRANCH
    check(32'h00000063, 32'h00000000);
    check(32'h00000463, 32'h00000008);
    check(32'h7E000F63, 32'h000007FE);
    check(32'hFE000EE3, 32'hFFFFFFFC);
    check(32'h80000063, 32'hFFFFF000);
    check(32'h7E000FE3, 32'h00000FFE);

    // U-Type: LUI
    check(32'h00000037, 32'h00000000);
    check(32'h12345037, 32'h12345000);
    check(32'h80000037, 32'h80000000);
    check(32'hFFFFF037, 32'hFFFFF000);

    // U-Type: AUIPC
    check(32'hAABCD017, 32'hAABCD000);

    // J-Type: JAL
    check(32'h0000006F, 32'h00000000);
    check(32'h0040006F, 32'h00000004);
    check(32'h0010006F, 32'h00000800);
    check(32'hFFFFF06F, 32'hFFFFFFFE);
    check(32'h8000006F, 32'hFFF00000);
    check(32'h7FFFF06F, 32'h000FFFFE);

    // Unsupported opcode
    check(32'h0000007F, 32'h00000000);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (failed == 0 && passed == 29)
      $display("IMMEDIATE GENERATOR VERIFICATION PASSED");
    else
      $fatal(1, "IMMEDIATE GENERATOR VERIFICATION FAILED");

    $finish;
  end

endmodule
