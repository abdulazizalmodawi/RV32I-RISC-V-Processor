`timescale 1ns / 1ps

module control_unit_tb;

  reg [6:0] opcode;

  wire reg_write;
  wire alu_src;
  wire alu_a_sel;
  wire mem_read;
  wire mem_write;
  wire branch;
  wire jump;
  wire jalr;
  wire [1:0] alu_op;
  wire [1:0] wb_sel;
  wire valid;

  integer passed = 0;
  integer failed = 0;

  wire [12:0] actual;

  control_unit dut (
    .opcode(opcode),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .alu_a_sel(alu_a_sel),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .alu_op(alu_op),
    .wb_sel(wb_sel),
    .valid(valid)
  );

  assign actual = {
    reg_write, alu_src, alu_a_sel,
    mem_read, mem_write, branch,
    jump, jalr, alu_op, wb_sel, valid
  };

  task check;
    input [6:0] test_opcode;
    input [12:0] expected;
    begin
      opcode = test_opcode;
      #10;

      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: opcode=%b", opcode);
      end else begin
        failed = failed + 1;
        $display("FAIL: opcode=%b expected=%b actual=%b",
                 opcode, expected, actual);
      end
    end
  endtask

  initial begin
    $display("Starting Control Unit verification...");

    // Valid instruction categories
    check(7'b0110011, 13'b10000000_10_00_1); // R-Type
    check(7'b0010011, 13'b11000000_10_00_1); // I-Type
    check(7'b0000011, 13'b11010000_00_01_1); // LOAD
    check(7'b0100011, 13'b01001000_00_00_1); // STORE
    check(7'b1100011, 13'b00000100_01_00_1); // BRANCH
    check(7'b1101111, 13'b10000010_00_10_1); // JAL
    check(7'b1100111, 13'b11000011_00_10_1); // JALR
    check(7'b0110111, 13'b10000000_00_11_1); // LUI
    check(7'b0010111, 13'b11100000_00_00_1); // AUIPC

    // Unsupported opcodes
    check(7'b1111111, 13'b00000000_00_00_0);
    check(7'b0000000, 13'b00000000_00_00_0);
    check(7'b1110011, 13'b00000000_00_00_0);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 12 && failed == 0)
      $display("CONTROL UNIT VERIFICATION PASSED");
    else
      $fatal(1, "CONTROL UNIT VERIFICATION FAILED");

    $finish;
  end

endmodule
