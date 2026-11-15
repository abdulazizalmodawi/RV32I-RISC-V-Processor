
module exception_detection_unit_tb;

  reg id_valid;
  reg id_illegal;
  reg [31:0] id_pc;
  reg [31:0] id_instruction;

  reg ex_valid;
  reg ex_control_transfer;
  reg ex_target_misaligned;
  reg [31:0] ex_pc;
  reg [31:0] ex_target_address;

  reg mem_valid;
  reg mem_read;
  reg mem_write;
  reg mem_address_misaligned;
  reg [31:0] mem_pc;
  reg [31:0] mem_address;

  wire exception_valid;
  wire [31:0] exception_cause;
  wire [31:0] exception_pc;
  wire [31:0] exception_tval;
  wire [1:0] exception_stage;

  integer passed;
  integer failed;

  exception_detection_unit dut (
    .id_valid(id_valid),
    .id_illegal(id_illegal),
    .id_pc(id_pc),
    .id_instruction(id_instruction),

    .ex_valid(ex_valid),
    .ex_control_transfer(ex_control_transfer),
    .ex_target_misaligned(ex_target_misaligned),
    .ex_pc(ex_pc),
    .ex_target_address(ex_target_address),

    .mem_valid(mem_valid),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_address_misaligned(mem_address_misaligned),
    .mem_pc(mem_pc),
    .mem_address(mem_address),

    .exception_valid(exception_valid),
    .exception_cause(exception_cause),
    .exception_pc(exception_pc),
    .exception_tval(exception_tval),
    .exception_stage(exception_stage)
  );

  task clear_inputs;
    begin
      id_valid = 0;
      id_illegal = 0;
      id_pc = 32'h00000020;
      id_instruction = 32'hFFFFFFFF;

      ex_valid = 0;
      ex_control_transfer = 0;
      ex_target_misaligned = 0;
      ex_pc = 32'h00000010;
      ex_target_address = 32'h00000022;

      mem_valid = 0;
      mem_read = 0;
      mem_write = 0;
      mem_address_misaligned = 0;
      mem_pc = 32'h00000008;
      mem_address = 32'h00000003;
    end
  endtask

  task check;
    input expected_valid;
    input [31:0] expected_cause;
    input [31:0] expected_pc;
    input [31:0] expected_tval;
    input [1:0] expected_stage;
    input [255:0] test_name;

    begin
      #1;

      if ({
        exception_valid,
        exception_cause,
        exception_pc,
        exception_tval,
        exception_stage
      } === {
        expected_valid,
        expected_cause,
        expected_pc,
        expected_tval,
        expected_stage
      }) begin

        passed = passed + 1;
        $display("PASS: %0s", test_name);

      end else begin

        failed = failed + 1;
        $display("FAIL: %0s", test_name);
        $display("Expected: valid=%b cause=%0d pc=%h tval=%h stage=%b",
          expected_valid, expected_cause,
          expected_pc, expected_tval, expected_stage);
        $display("Actual:   valid=%b cause=%0d pc=%h tval=%h stage=%b",
          exception_valid, exception_cause,
          exception_pc, exception_tval, exception_stage);

      end
    end
  endtask

  initial begin
    passed = 0;
    failed = 0;

    $display("==================================");
    $display(" EXCEPTION DETECTION UNIT TEST");
    $display("==================================");

    // Test 1: No exception
    clear_inputs();
    check(0, 0, 0, 0, 0, "No exception");

    // Test 2: Invalid ID stage must be ignored
    clear_inputs();
    id_illegal = 1;
    check(0, 0, 0, 0, 0, "Invalid ID ignored");

    // Test 3: Illegal instruction
    clear_inputs();
    id_valid = 1;
    id_illegal = 1;
    check(1, 2, 32'h20, 32'hFFFFFFFF, 1,
          "Illegal instruction");

    // Test 4: Legal ID instruction
    clear_inputs();
    id_valid = 1;
    check(0, 0, 0, 0, 0, "Legal ID instruction");

    // Test 5: Instruction target misaligned
    clear_inputs();
    ex_valid = 1;
    ex_control_transfer = 1;
    ex_target_misaligned = 1;
    check(1, 0, 32'h10, 32'h22, 2,
          "Instruction target misaligned");

    // Test 6: Invalid EX stage
    clear_inputs();
    ex_control_transfer = 1;
    ex_target_misaligned = 1;
    check(0, 0, 0, 0, 0, "Invalid EX ignored");

    // Test 7: No control transfer
    clear_inputs();
    ex_valid = 1;
    ex_target_misaligned = 1;
    check(0, 0, 0, 0, 0, "No control transfer");

    // Test 8: Aligned control target
    clear_inputs();
    ex_valid = 1;
    ex_control_transfer = 1;
    check(0, 0, 0, 0, 0, "Aligned target");

    // Test 9: Misaligned load
    clear_inputs();
    mem_valid = 1;
    mem_read = 1;
    mem_address_misaligned = 1;
    check(1, 4, 32'h08, 32'h03, 3,
          "Load address misaligned");

    // Test 10: Misaligned store
    clear_inputs();
    mem_valid = 1;
    mem_write = 1;
    mem_address_misaligned = 1;
    check(1, 6, 32'h08, 32'h03, 3,
          "Store address misaligned");

    // Test 11: Invalid MEM stage
    clear_inputs();
    mem_read = 1;
    mem_address_misaligned = 1;
    check(0, 0, 0, 0, 0, "Invalid MEM ignored");

    // Test 12: Aligned memory access
    clear_inputs();
    mem_valid = 1;
    mem_read = 1;
    check(0, 0, 0, 0, 0, "Aligned memory access");

    // Test 13: Conflicting read/write flags
    // This unit only handles single access exceptions.
    clear_inputs();
    mem_valid = 1;
    mem_read = 1;
    mem_write = 1;
    mem_address_misaligned = 1;
    check(0, 0, 0, 0, 0, "Conflicting MEM flags");

    // Test 14: MEM has priority over EX
    clear_inputs();
    mem_valid = 1;
    mem_read = 1;
    mem_address_misaligned = 1;
    ex_valid = 1;
    ex_control_transfer = 1;
    ex_target_misaligned = 1;
    check(1, 4, 32'h08, 32'h03, 3,
          "MEM priority over EX");

    // Test 15: MEM has priority over ID
    clear_inputs();
    mem_valid = 1;
    mem_write = 1;
    mem_address_misaligned = 1;
    id_valid = 1;
    id_illegal = 1;
    check(1, 6, 32'h08, 32'h03, 3,
          "MEM priority over ID");

    // Test 16: EX has priority over ID
    clear_inputs();
    ex_valid = 1;
    ex_control_transfer = 1;
    ex_target_misaligned = 1;
    id_valid = 1;
    id_illegal = 1;
    check(1, 0, 32'h10, 32'h22, 2,
          "EX priority over ID");

    // Test 17: All three stages report faults
    clear_inputs();
    mem_valid = 1;
    mem_read = 1;
    mem_address_misaligned = 1;
    ex_valid = 1;
    ex_control_transfer = 1;
    ex_target_misaligned = 1;
    id_valid = 1;
    id_illegal = 1;
    check(1, 4, 32'h08, 32'h03, 3,
          "MEM wins three-stage priority");

    // Test 18: Recovery after exceptions
    clear_inputs();
    check(0, 0, 0, 0, 0,
          "Recovery to no exception");

    $display("----------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 18 && failed == 0)
      $display("EXCEPTION DETECTION TEST PASSED");
    else
      $fatal(1, "EXCEPTION DETECTION TEST FAILED");

    $finish;
  end

endmodule
