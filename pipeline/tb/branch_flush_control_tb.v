timescale 1ns / 1ps

module branch_flush_control_tb;

  reg ex_valid;
  reg ex_branch;
  reg ex_branch_taken;
  reg ex_jump;
  reg ex_target_valid;

  wire pc_redirect;
  wire if_id_flush;
  wire id_ex_flush;

  integer passed = 0;
  integer failed = 0;

  branch_flush_control dut (
    .ex_valid(ex_valid),
    .ex_branch(ex_branch),
    .ex_branch_taken(ex_branch_taken),
    .ex_jump(ex_jump),
    .ex_target_valid(ex_target_valid),
    .pc_redirect(pc_redirect),
    .if_id_flush(if_id_flush),
    .id_ex_flush(id_ex_flush)
  );

  task clear_inputs;
    begin
      ex_valid = 1'b0;
      ex_branch = 1'b0;
      ex_branch_taken = 1'b0;
      ex_jump = 1'b0;
      ex_target_valid = 1'b1;
    end
  endtask

  task check;
    input [2:0] expected;
    input [255:0] test_name;
    begin
      #1;

      if ({pc_redirect, if_id_flush,
           id_ex_flush} === expected) begin

        passed = passed + 1;
        $display("PASS: %0s", test_name);

      end else begin

        failed = failed + 1;
        $display("FAIL: %0s", test_name);
        $display("Expected: %b", expected);
        $display("Actual:   %b",
                 {pc_redirect, if_id_flush,
                  id_ex_flush});

      end
    end
  endtask

  initial begin

    $display("Starting Branch Flush Control Test...");

    // Test 1: No valid instruction
    clear_inputs();
    check(3'b000, "No valid instruction");

    // Test 2: Normal arithmetic instruction
    clear_inputs();
    ex_valid = 1;
    check(3'b000, "Normal instruction");

    // Test 3: Branch not taken
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 0;
    check(3'b000, "Branch not taken");

    // Test 4: Taken branch
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 1;
    check(3'b111, "Taken branch");

    // Test 5: Valid JAL
    clear_inputs();
    ex_valid = 1;
    ex_jump = 1;
    check(3'b111, "JAL redirect");

    // Test 6: Valid JALR
    // JALR uses the same jump control signal.
    clear_inputs();
    ex_valid = 1;
    ex_jump = 1;
    ex_branch = 0;
    check(3'b111, "JALR redirect");

    // Test 7: Invalid instruction, taken branch
    clear_inputs();
    ex_valid = 0;
    ex_branch = 1;
    ex_branch_taken = 1;
    check(3'b000, "Invalid branch");

    // Test 8: Invalid instruction, jump
    clear_inputs();
    ex_valid = 0;
    ex_jump = 1;
    check(3'b000, "Invalid jump");

    // Test 9: Misaligned/invalid branch target
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 1;
    ex_target_valid = 0;
    check(3'b000, "Invalid branch target");

    // Test 10: Invalid jump target
    clear_inputs();
    ex_valid = 1;
    ex_jump = 1;
    ex_target_valid = 0;
    check(3'b000, "Invalid jump target");

    // Test 11: Unrelated branch_taken signal
    clear_inputs();
    ex_valid = 1;
    ex_branch_taken = 1;
    check(3'b000, "Branch disabled");

    // Test 12: Branch enabled but not taken,
    // target marked invalid.
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 0;
    ex_target_valid = 0;
    check(3'b000, "Not-taken invalid target");

    // Test 13: Jump and branch both asserted
    // Test control behavior even though this
    // combination is not a normal instruction.
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 1;
    ex_jump = 1;
    check(3'b111, "Combined control transfer");

    // Test 14: Recovery after redirect
    clear_inputs();
    ex_valid = 1;
    check(3'b000, "Recovery to sequential");

    // Test 15: Jump while branch not taken
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 0;
    ex_jump = 1;
    check(3'b111, "Jump overrides not-taken branch");

    // Test 16: Invalid target blocks all redirects
    clear_inputs();
    ex_valid = 1;
    ex_branch = 1;
    ex_branch_taken = 1;
    ex_jump = 1;
    ex_target_valid = 0;
    check(3'b000, "Target validity gate");

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("BRANCH FLUSH CONTROL TEST PASSED");
    else
      $fatal(1, "BRANCH FLUSH CONTROL TEST FAILED");

    $finish;

  end

endmodule
