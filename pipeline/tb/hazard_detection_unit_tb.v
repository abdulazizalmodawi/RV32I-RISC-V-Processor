timescale 1ns / 1ps

module hazard_detection_unit_tb;

  reg if_id_valid;
  reg [6:0] if_id_opcode;
  reg [4:0] if_id_rs1;
  reg [4:0] if_id_rs2;

  reg id_ex_valid;
  reg id_ex_mem_read;
  reg [4:0] id_ex_rd;

  wire pc_write;
  wire if_id_write;
  wire id_ex_flush;
  wire stall;

  integer passed = 0;
  integer failed = 0;

  hazard_detection_unit dut (
    .if_id_valid(if_id_valid),
    .if_id_opcode(if_id_opcode),
    .if_id_rs1(if_id_rs1),
    .if_id_rs2(if_id_rs2),
    .id_ex_valid(id_ex_valid),
    .id_ex_mem_read(id_ex_mem_read),
    .id_ex_rd(id_ex_rd),
    .pc_write(pc_write),
    .if_id_write(if_id_write),
    .id_ex_flush(id_ex_flush),
    .stall(stall)
  );

  task clear_inputs;
    begin
      if_id_valid = 1'b1;
      if_id_opcode = 7'b0110011;
      if_id_rs1 = 5'd1;
      if_id_rs2 = 5'd2;

      id_ex_valid = 1'b1;
      id_ex_mem_read = 1'b0;
      id_ex_rd = 5'd0;
    end
  endtask

  task check;
    input expected_stall;
    input [255:0] test_name;
    reg [3:0] expected;
    begin
      #1;

      if (expected_stall)
        expected = 4'b0011;
      else
        expected = 4'b1100;

      if ({pc_write, if_id_write,
           id_ex_flush, stall} === expected) begin

        passed = passed + 1;
        $display("PASS: %0s", test_name);

      end else begin

        failed = failed + 1;
        $display("FAIL: %0s", test_name);
        $display("Expected: %b", expected);
        $display("Actual:   %b",
                 {pc_write, if_id_write,
                  id_ex_flush, stall});

      end
    end
  endtask

  initial begin

    $display("Starting Hazard Detection Verification...");

    // Test 1: Normal operation
    clear_inputs();
    check(0, "No hazard");

    // Test 2: R-Type depends on LOAD via rs1
    clear_inputs();
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(1, "R-Type rs1 dependency");

    // Test 3: R-Type depends on LOAD via rs2
    clear_inputs();
    id_ex_mem_read = 1;
    id_ex_rd = 5'd2;
    check(1, "R-Type rs2 dependency");

    // Test 4: No matching source register
    clear_inputs();
    id_ex_mem_read = 1;
    id_ex_rd = 5'd3;
    check(0, "No register dependency");

    // Test 5: Never stall for x0
    clear_inputs();
    id_ex_mem_read = 1;
    id_ex_rd = 5'd0;
    if_id_rs1 = 5'd0;
    check(0, "Ignore x0");

    // Test 6: Invalid IF/ID instruction
    clear_inputs();
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    if_id_valid = 0;
    check(0, "Invalid IF/ID");

    // Test 7: Invalid ID/EX instruction
    clear_inputs();
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    id_ex_valid = 0;
    check(0, "Invalid ID/EX");

    // Test 8: EX-stage instruction is not LOAD
    clear_inputs();
    id_ex_rd = 5'd1;
    id_ex_mem_read = 0;
    check(0, "Non-LOAD instruction");

    // Test 9: I-Type uses rs1
    clear_inputs();
    if_id_opcode = 7'b0010011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(1, "I-Type rs1 dependency");

    // Test 10: I-Type does not use rs2
    clear_inputs();
    if_id_opcode = 7'b0010011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd2;
    check(0, "I-Type ignores rs2");

    // Test 11: STORE uses rs2
    clear_inputs();
    if_id_opcode = 7'b0100011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd2;
    check(1, "STORE rs2 dependency");

    // Test 12: STORE uses rs1
    clear_inputs();
    if_id_opcode = 7'b0100011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(1, "STORE rs1 dependency");

    // Test 13: BRANCH uses rs1
    clear_inputs();
    if_id_opcode = 7'b1100011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(1, "BRANCH rs1 dependency");

    // Test 14: BRANCH uses rs2
    clear_inputs();
    if_id_opcode = 7'b1100011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd2;
    check(1, "BRANCH rs2 dependency");

    // Test 15: JALR uses rs1
    clear_inputs();
    if_id_opcode = 7'b1100111;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(1, "JALR rs1 dependency");

    // Test 16: JAL does not use rs1/rs2
    clear_inputs();
    if_id_opcode = 7'b1101111;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(0, "JAL has no source dependency");

    // Test 17: LUI does not use rs1/rs2
    clear_inputs();
    if_id_opcode = 7'b0110111;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(0, "LUI has no source dependency");

    // Test 18: LOAD uses rs1
    clear_inputs();
    if_id_opcode = 7'b0000011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(1, "LOAD rs1 dependency");

    // Test 19: LOAD does not use rs2
    clear_inputs();
    if_id_opcode = 7'b0000011;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd2;
    check(0, "LOAD ignores rs2");

    // Test 20: AUIPC has no source dependency
    clear_inputs();
    if_id_opcode = 7'b0010111;
    id_ex_mem_read = 1;
    id_ex_rd = 5'd1;
    check(0, "AUIPC has no source dependency");

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 20 && failed == 0)
      $display("HAZARD DETECTION TEST PASSED");
    else
      $fatal(1, "HAZARD DETECTION TEST FAILED");

    $finish;

  end

endmodule
