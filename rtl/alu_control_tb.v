`timescale 1ns / 1ps

module alu_control_tb;

  reg [6:0] opcode;
  reg [1:0] alu_op;
  reg [2:0] funct3;
  reg [6:0] funct7;

  wire [3:0] alu_sel;
  wire valid;

  integer passed = 0;
  integer failed = 0;

  alu_control dut (
    .opcode(opcode),
    .alu_op(alu_op),
    .funct3(funct3),
    .funct7(funct7),
    .alu_sel(alu_sel),
    .valid(valid)
  );

  task check;
    input [6:0] test_opcode;
    input [1:0] test_alu_op;
    input [2:0] test_funct3;
    input [6:0] test_funct7;
    input [3:0] expected_sel;
    input expected_valid;
    begin
      opcode = test_opcode;
      alu_op = test_alu_op;
      funct3 = test_funct3;
      funct7 = test_funct7;
      #10;

      if (alu_sel === expected_sel &&
          valid === expected_valid) begin
        passed = passed + 1;
        $display("PASS: ALU select=%d valid=%b",
                 alu_sel, valid);
      end else begin
        failed = failed + 1;
        $display("FAIL: expected=%d/%b actual=%d/%b",
                 expected_sel, expected_valid,
                 alu_sel, valid);
      end
    end
  endtask

  initial begin
    $display("Starting ALU Control verification...");

    // R-Type operations
    check(7'b0110011,2'b10,3'b000,7'b0000000,4'd0,1'b1);
    check(7'b0110011,2'b10,3'b000,7'b0100000,4'd1,1'b1);
    check(7'b0110011,2'b10,3'b111,7'b0000000,4'd2,1'b1);
    check(7'b0110011,2'b10,3'b110,7'b0000000,4'd3,1'b1);
    check(7'b0110011,2'b10,3'b100,7'b0000000,4'd4,1'b1);
    check(7'b0110011,2'b10,3'b001,7'b0000000,4'd5,1'b1);
    check(7'b0110011,2'b10,3'b101,7'b0000000,4'd6,1'b1);
    check(7'b0110011,2'b10,3'b101,7'b0100000,4'd7,1'b1);
    check(7'b0110011,2'b10,3'b010,7'b0000000,4'd8,1'b1);
    check(7'b0110011,2'b10,3'b011,7'b0000000,4'd9,1'b1);

    // I-Type operations
    check(7'b0010011,2'b10,3'b000,7'b1111111,4'd0,1'b1);
    check(7'b0010011,2'b10,3'b111,7'b0000000,4'd2,1'b1);
    check(7'b0010011,2'b10,3'b110,7'b0000000,4'd3,1'b1);
    check(7'b0010011,2'b10,3'b100,7'b0000000,4'd4,1'b1);
    check(7'b0010011,2'b10,3'b010,7'b0000000,4'd8,1'b1);
    check(7'b0010011,2'b10,3'b011,7'b0000000,4'd9,1'b1);
    check(7'b0010011,2'b10,3'b001,7'b0000000,4'd5,1'b1);
    check(7'b0010011,2'b10,3'b101,7'b0000000,4'd6,1'b1);
    check(7'b0010011,2'b10,3'b101,7'b0100000,4'd7,1'b1);

    // Branch comparisons
    check(7'b1100011,2'b01,3'b000,7'b0000000,4'd1,1'b1);
    check(7'b1100011,2'b01,3'b001,7'b0000000,4'd1,1'b1);
    check(7'b1100011,2'b01,3'b100,7'b0000000,4'd8,1'b1);
    check(7'b1100011,2'b01,3'b101,7'b0000000,4'd8,1'b1);
    check(7'b1100011,2'b01,3'b110,7'b0000000,4'd9,1'b1);
    check(7'b1100011,2'b01,3'b111,7'b0000000,4'd9,1'b1);

    // Invalid combinations
    check(7'b0110011,2'b10,3'b000,7'b0000001,4'd0,1'b0);
    check(7'b0010011,2'b10,3'b001,7'b0100000,4'd0,1'b0);
    check(7'b1100011,2'b01,3'b010,7'b0000000,4'd0,1'b0);
    check(7'b0110011,2'b11,3'b000,7'b0000000,4'd0,1'b0);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 29 && failed == 0)
      $display("ALU CONTROL VERIFICATION PASSED");
    else
      $fatal(1, "ALU CONTROL VERIFICATION FAILED");

    $finish;
  end

endmodule
