`timescale 1ns / 1ps

module program_counter_tb;

  reg clk = 0;
  reg rst = 0;
  reg pc_write = 0;
  reg [31:0] next_pc = 0;

  wire [31:0] pc;

  integer passed = 0;
  integer failed = 0;

  program_counter dut (
    .clk(clk),
    .rst(rst),
    .pc_write(pc_write),
    .next_pc(next_pc),
    .pc(pc)
  );

  always #5 clk = ~clk;

  task check;
    input [31:0] expected;
    begin
      #1;
      if (pc === expected) begin
        passed = passed + 1;
        $display("PASS: PC=%h", pc);
      end else begin
        failed = failed + 1;
        $display("FAIL: expected=%h actual=%h",
                 expected, pc);
      end
    end
  endtask

  task update_pc;
    input [31:0] address;
    begin
      @(negedge clk);
      pc_write = 1;
      next_pc = address;
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    $display("Starting Program Counter verification...");

    // Test 1: Reset sets PC to zero
    @(negedge clk);
    rst = 1;
    @(posedge clk);
    #1;
    check(32'h00000000);
    rst = 0;

    // Test 2: Load address 4
    update_pc(32'h00000004);
    check(32'h00000004);

    // Test 3: Load address 8
    update_pc(32'h00000008);
    check(32'h00000008);

    // Test 4: Load address 12
    update_pc(32'h0000000C);
    check(32'h0000000C);

    // Test 5: Disable PC update
    @(negedge clk);
    pc_write = 0;
    next_pc = 32'h00000100;
    @(posedge clk);
    #1;
    check(32'h0000000C);

    // Test 6: Load a branch target
    update_pc(32'h00000100);
    check(32'h00000100);

    // Test 7: Load a jump target
    update_pc(32'h00001000);
    check(32'h00001000);

    // Test 8: Load maximum 32-bit address
    update_pc(32'hFFFFFFFC);
    check(32'hFFFFFFFC);

    // Test 9: PC holds its value
    @(negedge clk);
    pc_write = 0;
    next_pc = 32'h00000020;
    @(posedge clk);
    #1;
    check(32'hFFFFFFFC);

    // Test 10: Reset clears PC
    @(negedge clk);
    rst = 1;
    @(posedge clk);
    #1;
    check(32'h00000000);
    rst = 0;

    // Test 11: Load address after reset
    update_pc(32'h00000020);
    check(32'h00000020);

    // Test 12: Reset has priority over write
    @(negedge clk);
    rst = 1;
    pc_write = 1;
    next_pc = 32'h00000200;
    @(posedge clk);
    #1;
    check(32'h00000000);
    rst = 0;

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 12 && failed == 0)
      $display("PROGRAM COUNTER VERIFICATION PASSED");
    else
      $fatal(1, "PROGRAM COUNTER VERIFICATION FAILED");

    $finish;
  end

endmodule
