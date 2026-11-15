module processor_pipeline_top_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;
  integer i;

  processor_pipeline_top dut (
    .clk(clk),
    .rst(rst)
  );

  // Clock cycle
  task tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  // Check register contents
  task check_reg;
    input [4:0] reg_num;
    input [31:0] expected;
    begin
      if (dut.rf.registers[reg_num] === expected) begin
        passed = passed + 1;
        $display("PASS: x%0d = %0d",
                 reg_num, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: x%0d", reg_num);
        $display("Expected: %0d", expected);
        $display("Actual:   %0d",
                 dut.rf.registers[reg_num]);
      end
    end
  endtask

  initial begin

    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;

    // Allow memory initialization to complete
    #2;

    // -------------------------------------------
    // Arithmetic and data forwarding
    // -------------------------------------------

    // 0x00: addi x1, x0, 5
    dut.imem.memory[0] = 32'h00500093;

    // 0x04: addi x2, x0, 7
    dut.imem.memory[1] = 32'h00700113;

    // 0x08: add x3, x1, x2
    dut.imem.memory[2] = 32'h002081b3;

    // 0x0C: sub x4, x3, x1
    dut.imem.memory[3] = 32'h40118233;

    // -------------------------------------------
    // Upper immediate instructions
    // -------------------------------------------

    // 0x10: lui x5, 0x1
    dut.imem.memory[4] = 32'h000012b7;

    // 0x14: auipc x6, 0
    dut.imem.memory[5] = 32'h00000317;

    // -------------------------------------------
    // Memory operations and load-use hazard
    // -------------------------------------------

    // 0x18: sw x3, 0(x0)
    dut.imem.memory[6] = 32'h00302023;

    // 0x1C: lw x7, 0(x0)
    dut.imem.memory[7] = 32'h00002383;

    // 0x20: add x8, x7, x1
    // Must stall for load-use dependency
    dut.imem.memory[8] = 32'h00138433;

    // -------------------------------------------
    // Taken branch and instruction flushing
    // -------------------------------------------

    // 0x24: beq x8, x8, 8
    dut.imem.memory[9] = 32'h00840463;

    // 0x28: wrong-path instruction
    dut.imem.memory[10] = 32'h06300493;

    // 0x2C: addi x9, x0, 42
    dut.imem.memory[11] = 32'h02a00493;

    // -------------------------------------------
    // JAL and instruction flushing
    // -------------------------------------------

    // 0x30: jal x10, 8
    dut.imem.memory[12] = 32'h0080056f;

    // 0x34: wrong-path instruction
    dut.imem.memory[13] = 32'h06300593;

    // 0x38: addi x11, x0, 22
    dut.imem.memory[14] = 32'h01600593;

    // -------------------------------------------
    // JALR and forwarding
    // -------------------------------------------

    // 0x3C: addi x12, x0, 72
    dut.imem.memory[15] = 32'h04800613;

    // 0x40: jalr x13, 0(x12)
    dut.imem.memory[16] = 32'h000606e7;

    // 0x44: wrong-path instruction
    dut.imem.memory[17] = 32'h06300713;

    // 0x48: addi x14, x0, 33
    dut.imem.memory[18] = 32'h02100713;

    // Reset processor
    repeat (2) tick();

    rst = 0;

    // Allow instructions to travel through
    // all five pipeline stages
    repeat (40) tick();

    $display("");
    $display("====================================");
    $display(" RV32I PIPELINE INTEGRATION TEST");
    $display("====================================");

    check_reg(5'd0,  32'd0);
    check_reg(5'd1,  32'd5);
    check_reg(5'd2,  32'd7);
    check_reg(5'd3,  32'd12);
    check_reg(5'd4,  32'd7);
    check_reg(5'd5,  32'd4096);
    check_reg(5'd6,  32'd20);
    check_reg(5'd7,  32'd12);
    check_reg(5'd8,  32'd17);
    check_reg(5'd9,  32'd42);
    check_reg(5'd10, 32'd52);
    check_reg(5'd11, 32'd22);
    check_reg(5'd12, 32'd72);
    check_reg(5'd13, 32'd68);
    check_reg(5'd14, 32'd33);

    // Verify stored word in little-endian order
    if ({dut.dmem.memory[3],
         dut.dmem.memory[2],
         dut.dmem.memory[1],
         dut.dmem.memory[0]} === 32'd12) begin

      passed = passed + 1;
      $display("PASS: Memory word = 12");

    end else begin

      failed = failed + 1;
      $display("FAIL: Memory word mismatch");

    end

    $display("------------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("PIPELINE INTEGRATION TEST PASSED");
    else
      $fatal(1, "PIPELINE INTEGRATION TEST FAILED");

    $finish;

  end

endmodule
