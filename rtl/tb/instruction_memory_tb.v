`timescale 1ns / 1ps

module instruction_memory_tb;

  reg [31:0] pc;
  wire [31:0] instruction;
  wire valid;

  integer passed = 0;
  integer failed = 0;

  instruction_memory dut (
    .pc(pc),
    .instruction(instruction),
    .valid(valid)
  );

  task check;
    input [31:0] test_pc;
    input [31:0] expected_instruction;
    input expected_valid;
    begin
      pc = test_pc;
      #10;

      if ((instruction === expected_instruction) &&
          (valid === expected_valid)) begin
        passed = passed + 1;
        $display("PASS: PC=%h instruction=%h valid=%b",
                 pc, instruction, valid);
      end else begin
        failed = failed + 1;
        $display("FAIL: PC=%h expected=%h/%b actual=%h/%b",
                 pc, expected_instruction, expected_valid,
                 instruction, valid);
      end
    end
  endtask

  initial begin
    $display("Starting Instruction Memory verification...");

    // Check initial NOP values
    check(32'd0, 32'h00000013, 1'b1);
    check(32'd4, 32'h00000013, 1'b1);
    check(32'd1020, 32'h00000013, 1'b1);

    // Load sample instructions for testing
    dut.memory[0] = 32'h00500093;
    dut.memory[1] = 32'h00308113;
    dut.memory[2] = 32'h002081B3;
    dut.memory[3] = 32'h0000006F;
    dut.memory[255] = 32'hFFFFFFFF;

    // Verify instruction fetching
    check(32'd0, 32'h00500093, 1'b1);
    check(32'd4, 32'h00308113, 1'b1);
    check(32'd8, 32'h002081B3, 1'b1);
    check(32'd12, 32'h0000006F, 1'b1);

    // Last valid memory address
    check(32'd1020, 32'hFFFFFFFF, 1'b1);

    // Unmodified location remains NOP
    check(32'd16, 32'h00000013, 1'b1);

    // Misaligned addresses
    check(32'd1, 32'h00000013, 1'b0);
    check(32'd2, 32'h00000013, 1'b0);
    check(32'd1021, 32'h00000013, 1'b0);

    // Out-of-range addresses
    check(32'd1024, 32'h00000013, 1'b0);
    check(32'hFFFFFFFC, 32'h00000013, 1'b0);
    check(32'h00010000, 32'h00000013, 1'b0);

    // Repeat a valid fetch
    check(32'd4, 32'h00308113, 1'b1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("INSTRUCTION MEMORY VERIFICATION PASSED");
    else
      $fatal(1, "INSTRUCTION MEMORY VERIFICATION FAILED");

    $finish;
  end

endmodule
