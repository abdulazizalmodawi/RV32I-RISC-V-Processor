`timescale 1ns / 1ps

module branch_control_tb;

  reg branch_en;
  reg [2:0] funct3;
  reg [31:0] rs1_data;
  reg [31:0] rs2_data;

  wire branch_taken;
  wire valid;

  integer passed = 0;
  integer failed = 0;

  branch_control dut (
    .branch_en(branch_en),
    .funct3(funct3),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .branch_taken(branch_taken),
    .valid(valid)
  );

  task check;
    input test_enable;
    input [2:0] test_funct3;
    input [31:0] test_a;
    input [31:0] test_b;
    input expected_taken;
    input expected_valid;

    begin
      branch_en = test_enable;
      funct3 = test_funct3;
      rs1_data = test_a;
      rs2_data = test_b;

      #10;

      if ((branch_taken === expected_taken) &&
          (valid === expected_valid)) begin
        passed = passed + 1;
        $display("PASS: funct3=%b taken=%b valid=%b",
                 funct3, branch_taken, valid);
      end else begin
        failed = failed + 1;
        $display(
          "FAIL: funct3=%b expected=%b/%b actual=%b/%b",
          funct3, expected_taken, expected_valid,
          branch_taken, valid
        );
      end
    end
  endtask

  initial begin
    $display("Starting Branch Control verification...");

    // BEQ: equal and not equal
    check(1, 3'b000, 32'd10, 32'd10, 1, 1);
    check(1, 3'b000, 32'd10, 32'd20, 0, 1);

    // BNE: not equal and equal
    check(1, 3'b001, 32'd10, 32'd20, 1, 1);
    check(1, 3'b001, 32'd10, 32'd10, 0, 1);

    // BLT: signed comparison
    check(1, 3'b100, 32'd5, 32'd10, 1, 1);
    check(1, 3'b100, 32'd10, 32'd5, 0, 1);

    // BGE: signed comparison
    check(1, 3'b101, 32'd10, 32'd5, 1, 1);
    check(1, 3'b101, 32'd5, 32'd10, 0, 1);

    // BLTU: unsigned comparison
    check(1, 3'b110, 32'd5, 32'd10, 1, 1);
    check(1, 3'b110, 32'd10, 32'd5, 0, 1);

    // BGEU: unsigned comparison
    check(1, 3'b111, 32'd10, 32'd5, 1, 1);
    check(1, 3'b111, 32'd5, 32'd10, 0, 1);

    // Signed boundary cases
    check(1, 3'b100, 32'hFFFFFFFF, 32'd1, 1, 1);
    check(1, 3'b101, 32'hFFFFFFFF, 32'd1, 0, 1);

    // Unsigned boundary cases
    check(1, 3'b110, 32'hFFFFFFFF, 32'd1, 0, 1);
    check(1, 3'b111, 32'hFFFFFFFF, 32'd1, 1, 1);

    // Branch disabled
    check(0, 3'b000, 32'd5, 32'd5, 0, 1);
    check(0, 3'b001, 32'd5, 32'd6, 0, 1);

    // Unsupported branch conditions
    check(1, 3'b010, 32'd1, 32'd2, 0, 0);
    check(1, 3'b011, 32'd1, 32'd2, 0, 0);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 20 && failed == 0)
      $display("BRANCH CONTROL VERIFICATION PASSED");
    else
      $fatal(1, "BRANCH CONTROL VERIFICATION FAILED");

    $finish;
  end

endmodule
