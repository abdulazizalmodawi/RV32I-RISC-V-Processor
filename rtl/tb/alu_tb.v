`timescale 1ns / 1ps

module alu_tb;

  reg  [31:0] a, b;
  reg  [3:0]  alu_op;
  wire [31:0] result;

  integer passed = 0;
  integer failed = 0;

  alu dut (
    .a(a),
    .b(b),
    .alu_op(alu_op),
    .result(result)
  );

  task check;
    input [31:0] test_a;
    input [31:0] test_b;
    input [3:0]  test_op;
    input [31:0] expected;
    begin
      a = test_a;
      b = test_b;
      alu_op = test_op;
      #10;

      if (result === expected) begin
        $display("PASS: op=%b result=%h", test_op, result);
        passed = passed + 1;
      end else begin
        $display("FAIL: op=%b expected=%h actual=%h",
                 test_op, expected, result);
        failed = failed + 1;
      end
    end
  endtask

  initial begin
    $display("Starting ALU verification...");

    check(32'd20, 32'd10, 4'd0, 32'd30);
    check(32'd20, 32'd10, 4'd1, 32'd10);
    check(32'hF0F0, 32'h0FF0, 4'd2, 32'h00F0);
    check(32'hF0F0, 32'h0FF0, 4'd3, 32'hFFF0);
    check(32'hF0F0, 32'h0FF0, 4'd4, 32'hFF00);
    check(32'd1, 32'd4, 4'd5, 32'd16);
    check(32'd16, 32'd2, 4'd6, 32'd4);
    check(32'hFFFFFFF0, 32'd2, 4'd7, 32'hFFFFFFFC);
    check(32'hFFFFFFFF, 32'd1, 4'd8, 32'd1);
    check(32'hFFFFFFFF, 32'd1, 4'd9, 32'd0);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (failed == 0)
      $display("ALU VERIFICATION PASSED");
    else
      $fatal(1, "ALU VERIFICATION FAILED");

    $finish;
  end

endmodule
