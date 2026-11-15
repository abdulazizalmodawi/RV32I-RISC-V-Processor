
`timescale 1ns / 1ps

module ex_mem_trap_reg_tb;

  reg clk, rst, stall, flush;
  reg valid_in;

  reg [31:0] pc_in;
  reg [31:0] pc_plus4_in;
  reg [31:0] alu_result_in;
  reg [31:0] rs2_data_in;
  reg [31:0] immediate_in;

  reg [4:0] rd_in;
  reg [2:0] funct3_in;

  reg reg_write_in;
  reg mem_read_in;
  reg mem_write_in;
  reg [1:0] wb_sel_in;

  wire valid_out;
  wire [31:0] pc_out;
  wire [31:0] pc_plus4_out;
  wire [31:0] alu_result_out;
  wire [31:0] rs2_data_out;
  wire [31:0] immediate_out;

  wire [4:0] rd_out;
  wire [2:0] funct3_out;
  wire reg_write_out;
  wire mem_read_out;
  wire mem_write_out;
  wire [1:0] wb_sel_out;

  integer passed;
  integer failed;

  // Full registered output bundle: 174 bits
  wire [173:0] actual;

  assign actual = {
    valid_out,
    pc_out,
    pc_plus4_out,
    alu_result_out,
    rs2_data_out,
    immediate_out,
    rd_out,
    funct3_out,
    reg_write_out,
    mem_read_out,
    mem_write_out,
    wb_sel_out
  };

  ex_mem_trap_reg dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),

    .valid_in(valid_in),
    .pc_in(pc_in),
    .pc_plus4_in(pc_plus4_in),
    .alu_result_in(alu_result_in),
    .rs2_data_in(rs2_data_in),
    .immediate_in(immediate_in),

    .rd_in(rd_in),
    .funct3_in(funct3_in),

    .reg_write_in(reg_write_in),
    .mem_read_in(mem_read_in),
    .mem_write_in(mem_write_in),
    .wb_sel_in(wb_sel_in),

    .valid_out(valid_out),
    .pc_out(pc_out),
    .pc_plus4_out(pc_plus4_out),
    .alu_result_out(alu_result_out),
    .rs2_data_out(rs2_data_out),
    .immediate_out(immediate_out),

    .rd_out(rd_out),
    .funct3_out(funct3_out),

    .reg_write_out(reg_write_out),
    .mem_read_out(mem_read_out),
    .mem_write_out(mem_write_out),
    .wb_sel_out(wb_sel_out)
  );

  task tick;
    begin
      #5 clk = 1'b1;
      #1;
      clk = 1'b0;
      #4;
    end
  endtask

  task set_inputs;
    input [31:0] pc_value;
    input [31:0] result_value;
    input [4:0] destination;
    begin
      valid_in = 1'b1;
      pc_in = pc_value;
      pc_plus4_in = pc_value + 32'd4;
      alu_result_in = result_value;
      rs2_data_in = 32'h12345678;
      immediate_in = 32'h00000020;
      rd_in = destination;
      funct3_in = 3'b010;
      reg_write_in = 1'b1;
      mem_read_in = 1'b0;
      mem_write_in = 1'b0;
      wb_sel_in = 2'b00;
    end
  endtask

  task check;
    input [173:0] expected;
    input [255:0] name;
    begin
      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", name);
        $display("Expected: %h", expected);
        $display("Actual:   %h", actual);
      end
    end
  endtask

  task check_current_inputs;
    input [255:0] name;
    begin
      check({
        valid_in,
        pc_in,
        pc_plus4_in,
        alu_result_in,
        rs2_data_in,
        immediate_in,
        rd_in,
        funct3_in,
        reg_write_in,
        mem_read_in,
        mem_write_in,
        wb_sel_in
      }, name);
    end
  endtask

  reg [173:0] saved_state;

  initial begin
    clk = 0;
    rst = 0;
    stall = 0;
    flush = 0;
    passed = 0;
    failed = 0;

    set_inputs(32'h20, 32'd100, 5'd5);

    // Test 1: Reset
    rst = 1;
    tick();
    check(174'd0, "Reset clears all outputs");

    // Test 2: Normal transfer
    rst = 0;
    tick();
    check_current_inputs("Normal transfer");

    // Test 3: Original PC preserved
    if (pc_out === 32'h20) begin
      passed = passed + 1;
      $display("PASS: Original PC preserved");
    end else begin
      failed = failed + 1;
      $display("FAIL: Original PC");
    end

    // Test 4: PC+4 preserved
    if (pc_plus4_out === 32'h24) begin
      passed = passed + 1;
      $display("PASS: PC plus four");
    end else begin
      failed = failed + 1;
      $display("FAIL: PC plus four");
    end

    // Test 5: Hold during stall
    saved_state = actual;
    stall = 1;
    set_inputs(32'h40, 32'd200, 5'd6);
    tick();
    check(saved_state, "Stall holds data");

    // Test 6: Flush overrides stall
    flush = 1;
    tick();
    check(174'd0, "Flush overrides stall");

    // Test 7: Stall holds empty bubble
    flush = 0;
    tick();
    check(174'd0, "Stall retains bubble");

    // Test 8: Resume normal operation
    stall = 0;
    tick();
    check_current_inputs("Resume after stall");

    // Test 9: LOAD instruction
    set_inputs(32'h60, 32'h00000100, 5'd7);
    mem_read_in = 1;
    wb_sel_in = 2'b01;
    tick();
    check_current_inputs("LOAD information transfer");

    // Test 10: STORE instruction
    set_inputs(32'h80, 32'h00000104, 5'd0);
    reg_write_in = 0;
    mem_write_in = 1;
    tick();
    check_current_inputs("STORE information transfer");

    // Test 11: Invalid instruction
    set_inputs(32'hA0, 32'd0, 5'd0);
    valid_in = 0;
    reg_write_in = 0;
    tick();
    check_current_inputs("Invalid instruction transfer");

    // Test 12: Flush invalid instruction
    flush = 1;
    tick();
    check(174'd0, "Flush invalid instruction");

    // Test 13: New PC after flush
    flush = 0;
    set_inputs(32'hC0, 32'd300, 5'd8);
    tick();
    check_current_inputs("New PC after flush");

    // Test 14: Synchronous update only
    saved_state = actual;
    set_inputs(32'hE0, 32'd400, 5'd9);
    #2;
    check(saved_state, "No update before clock edge");

    // Test 15: Clock captures new values
    tick();
    check_current_inputs("Clock captures new values");

    // Test 16: Reset highest priority
    rst = 1;
    stall = 1;
    flush = 1;
    tick();
    check(174'd0, "Reset highest priority");

    $display("--------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("EX/MEM TRAP REGISTER TEST PASSED");
    else
      $fatal(1, "EX/MEM TRAP REGISTER TEST FAILED");

    $finish;
  end

endmodule
