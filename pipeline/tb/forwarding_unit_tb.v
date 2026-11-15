

module forwarding_unit_tb;

  reg [4:0] id_ex_rs1;
  reg [4:0] id_ex_rs2;

  reg [4:0] ex_mem_rd;
  reg ex_mem_valid;
  reg ex_mem_reg_write;
  reg ex_mem_mem_read;

  reg [4:0] mem_wb_rd;
  reg mem_wb_valid;
  reg mem_wb_reg_write;

  wire [1:0] forward_a;
  wire [1:0] forward_b;

  integer passed = 0;
  integer failed = 0;

  forwarding_unit dut (
    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),

    .ex_mem_rd(ex_mem_rd),
    .ex_mem_valid(ex_mem_valid),
    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_mem_read(ex_mem_mem_read),

    .mem_wb_rd(mem_wb_rd),
    .mem_wb_valid(mem_wb_valid),
    .mem_wb_reg_write(mem_wb_reg_write),

    .forward_a(forward_a),
    .forward_b(forward_b)
  );

  task check;
    input [1:0] expected_a;
    input [1:0] expected_b;
    input [255:0] test_name;
    begin
      #1;

      if (forward_a === expected_a &&
          forward_b === expected_b) begin
        passed = passed + 1;
        $display("PASS: %0s", test_name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", test_name);
        $display("Expected A=%b B=%b",
                 expected_a, expected_b);
        $display("Actual   A=%b B=%b",
                 forward_a, forward_b);
      end
    end
  endtask

  task clear_inputs;
    begin
      id_ex_rs1 = 5'd1;
      id_ex_rs2 = 5'd2;

      ex_mem_rd = 5'd0;
      ex_mem_valid = 0;
      ex_mem_reg_write = 0;
      ex_mem_mem_read = 0;

      mem_wb_rd = 5'd0;
      mem_wb_valid = 0;
      mem_wb_reg_write = 0;
    end
  endtask

  initial begin
    $display("Starting Forwarding Unit Verification...");

    // Test 1: No forwarding
    clear_inputs();
    check(2'b00, 2'b00, "No forwarding");

    // Test 2: EX/MEM forwards to operand A
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd1;
    check(2'b10, 2'b00, "EX/MEM to A");

    // Test 3: EX/MEM forwards to operand B
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd2;
    check(2'b00, 2'b10, "EX/MEM to B");

    // Test 4: MEM/WB forwards to operand A
    clear_inputs();
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd1;
    check(2'b01, 2'b00, "MEM/WB to A");

    // Test 5: MEM/WB forwards to operand B
    clear_inputs();
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd2;
    check(2'b00, 2'b01, "MEM/WB to B");

    // Test 6: EX/MEM takes priority
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd1;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd1;
    check(2'b10, 2'b00, "EX/MEM priority");

    // Test 7: Different sources for A and B
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd1;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd2;
    check(2'b10, 2'b01, "Independent A and B");

    // Test 8: Never forward from x0
    clear_inputs();
    id_ex_rs1 = 5'd0;
    id_ex_rs2 = 5'd0;
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd0;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd0;
    check(2'b00, 2'b00, "Ignore x0");

    // Test 9: EX/MEM write disabled
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_rd = 5'd1;
    ex_mem_reg_write = 0;
    check(2'b00, 2'b00, "EX/MEM write disabled");

    // Test 10: MEM/WB invalid
    clear_inputs();
    mem_wb_rd = 5'd2;
    mem_wb_reg_write = 1;
    mem_wb_valid = 0;
    check(2'b00, 2'b00, "Invalid MEM/WB");

    // Test 11: Do not forward load from EX/MEM
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_mem_read = 1;
    ex_mem_rd = 5'd1;
    check(2'b00, 2'b00, "Load not ready");

    // Test 12: Older MEM/WB value must not
    // override a newer EX/MEM load dependency.
    // Hazard Detection must stall this case.
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_mem_read = 1;
    ex_mem_rd = 5'd1;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd1;
    check(2'b00, 2'b00, "Load dependency blocks old WB");

    // Test 13: MEM/WB value available when
    // EX/MEM is an unrelated load
    clear_inputs();
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_mem_read = 1;
    ex_mem_rd = 5'd3;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd1;
    check(2'b01, 2'b00, "Unrelated load");

    // Test 14: Both operands use EX/MEM
    clear_inputs();
    id_ex_rs1 = 5'd5;
    id_ex_rs2 = 5'd5;
    ex_mem_valid = 1;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd5;
    check(2'b10, 2'b10, "Both operands EX/MEM");

    // Test 15: Both operands use MEM/WB
    clear_inputs();
    id_ex_rs1 = 5'd7;
    id_ex_rs2 = 5'd7;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd7;
    check(2'b01, 2'b01, "Both operands MEM/WB");

    // Test 16: EX/MEM invalid; use MEM/WB
    clear_inputs();
    ex_mem_valid = 0;
    ex_mem_reg_write = 1;
    ex_mem_rd = 5'd1;
    mem_wb_valid = 1;
    mem_wb_reg_write = 1;
    mem_wb_rd = 5'd1;
    check(2'b01, 2'b00, "Invalid EX/MEM fallback");

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("FORWARDING UNIT TEST PASSED");
    else
      $fatal(1, "FORWARDING UNIT TEST FAILED");

    $finish;
  end

endmodule
