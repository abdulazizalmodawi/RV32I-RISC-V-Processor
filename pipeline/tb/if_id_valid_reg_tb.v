
`timescale 1ns / 1ps

module if_id_valid_reg_tb;

  reg clk;
  reg rst;
  reg stall;
  reg flush;
  reg valid_in;

  wire valid_out;

  integer passed;
  integer failed;

  if_id_valid_reg dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),
    .valid_in(valid_in),
    .valid_out(valid_out)
  );

  // One complete clock cycle
  task tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  // Verify registered output
  task check;
    input expected;
    input [255:0] name;
    begin
      if (valid_out === expected) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", name);
        $display("Expected: %b, Actual: %b",
                 expected, valid_out);
      end
    end
  endtask

  initial begin

    clk = 0;
    rst = 0;
    stall = 0;
    flush = 0;
    valid_in = 0;
    passed = 0;
    failed = 0;

    // Test 1: Reset clears validity
    rst = 1;
    tick();
    check(1'b0, "Reset clears validity");

    // Test 2: Capture valid instruction
    rst = 0;
    valid_in = 1;
    tick();
    check(1'b1, "Capture valid instruction");

    // Test 3: Hold valid during stall
    stall = 1;
    valid_in = 0;
    tick();
    check(1'b1, "Stall holds valid");

    // Test 4: Flush overrides stall
    flush = 1;
    tick();
    check(1'b0, "Flush overrides stall");

    // Test 5: Stall holds invalid
    flush = 0;
    valid_in = 1;
    tick();
    check(1'b0, "Stall holds invalid");

    // Test 6: Resume after stall
    stall = 0;
    tick();
    check(1'b1, "Resume after stall");

    // Test 7: Capture invalid instruction
    valid_in = 0;
    tick();
    check(1'b0, "Capture invalid instruction");

    // Test 8: Return to valid
    valid_in = 1;
    tick();
    check(1'b1, "Return to valid");

    // Test 9: Flush active
    flush = 1;
    tick();
    check(1'b0, "Flush clears valid");

    // Test 10: Remain invalid while flushed
    valid_in = 1;
    tick();
    check(1'b0, "Flush remains active");

    // Test 11: Recover from flush
    flush = 0;
    tick();
    check(1'b1, "Recover from flush");

    // Test 12: Reset overrides stall and flush
    rst = 1;
    stall = 1;
    flush = 1;
    tick();
    check(1'b0, "Reset highest priority");

    // Test 13: Stall after reset
    rst = 0;
    flush = 0;
    valid_in = 1;
    tick();
    check(1'b0, "Stall after reset");

    // Test 14: Release stall
    stall = 0;
    tick();
    check(1'b1, "Release stall");

    // Test 15: Output unchanged before clock
    valid_in = 0;
    #2;
    check(1'b1, "Synchronous update only");

    // Test 16: Update on next clock
    tick();
    check(1'b0, "Update on next clock");

    $display("-----------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("IF/ID VALID REGISTER TEST PASSED");
    else
      $fatal(1, "IF/ID VALID REGISTER TEST FAILED");

    $finish;
  end

endmodule
