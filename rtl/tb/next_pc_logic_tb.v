`timescale 1ns / 1ps

module next_pc_logic_tb;

  reg [31:0] pc;
  reg [31:0] immediate;
  reg [31:0] rs1_data;
  reg branch_taken;
  reg jump;
  reg jalr;

  wire [31:0] next_pc;

  integer passed = 0;
  integer failed = 0;

  next_pc_logic dut (
    .pc(pc),
    .immediate(immediate),
    .rs1_data(rs1_data),
    .branch_taken(branch_taken),
    .jump(jump),
    .jalr(jalr),
    .next_pc(next_pc)
  );

  task check;
    input [31:0] test_pc;
    input [31:0] test_imm;
    input [31:0] test_rs1;
    input test_branch;
    input test_jump;
    input test_jalr;
    input [31:0] expected;

    begin
      pc = test_pc;
      immediate = test_imm;
      rs1_data = test_rs1;
      branch_taken = test_branch;
      jump = test_jump;
      jalr = test_jalr;

      #10;

      if (next_pc === expected) begin
        passed = passed + 1;
        $display("PASS: next_pc=%h", next_pc);
      end else begin
        failed = failed + 1;
        $display("FAIL: expected=%h actual=%h",
                 expected, next_pc);
      end
    end
  endtask

  initial begin
    $display("Starting Next PC Logic verification...");

    // Sequential PC + 4
    check(32'h00000000, 32'd0, 32'd0,
          0, 0, 0, 32'h00000004);

    check(32'h00000004, 32'd0, 32'd0,
          0, 0, 0, 32'h00000008);

    check(32'h00000100, 32'd0, 32'd0,
          0, 0, 0, 32'h00000104);

    // Branch not taken
    check(32'h00000100, 32'd16, 32'd0,
          0, 0, 0, 32'h00000104);

    // Forward branch
    check(32'h00000100, 32'd16, 32'd0,
          1, 0, 0, 32'h00000110);

    // Backward branch
    check(32'h00000100, 32'hFFFFFFF0, 32'd0,
          1, 0, 0, 32'h000000F0);

    // JAL forward jump
    check(32'h00000200, 32'd32, 32'd0,
          0, 1, 0, 32'h00000220);

    // JAL backward jump
    check(32'h00000200, 32'hFFFFFFE0, 32'd0,
          0, 1, 0, 32'h000001E0);

    // JALR: rs1 + immediate
    check(32'h00000100, 32'd8, 32'h00000300,
          0, 1, 1, 32'h00000308);

    // JALR: clear least significant bit
    check(32'h00000100, 32'd5, 32'h00000300,
          0, 1, 1, 32'h00000304);

    // JALR negative offset
    check(32'h00000100, 32'hFFFFFFFC,
          32'h00000300,
          0, 1, 1, 32'h000002FC);

    // PC + 4 wraparound
    check(32'hFFFFFFFC, 32'd0, 32'd0,
          0, 0, 0, 32'h00000000);

    // Jump has priority over branch
    check(32'h00000100, 32'd16, 32'd0,
          1, 1, 0, 32'h00000110);

    // JALR target independent of PC
    check(32'h00000500, 32'd12,
          32'h00000200,
          0, 1, 1, 32'h0000020C);

    // JALR flag alone must not trigger jump
    check(32'h00000100, 32'd16,
          32'h00000300,
          0, 0, 1, 32'h00000104);

    // Branch target wraparound
    check(32'hFFFFFFF8, 32'd16, 32'd0,
          1, 0, 0, 32'h00000008);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("NEXT PC LOGIC VERIFICATION PASSED");
    else
      $fatal(1, "NEXT PC LOGIC VERIFICATION FAILED");

    $finish;
  end

endmodule
