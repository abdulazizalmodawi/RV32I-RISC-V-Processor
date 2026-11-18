`timescale 1ns / 1ps

module mem_wb_reg_tb;

  reg clk = 0;
  reg rst = 1;
  reg stall = 0;
  reg flush = 0;

  reg valid_in = 0;
  reg [31:0] pc_plus4_in = 0;
  reg [31:0] alu_result_in = 0;
  reg [31:0] memory_data_in = 0;
  reg [31:0] immediate_in = 0;

  reg [4:0] rd_in = 0;
  reg reg_write_in = 0;
  reg [1:0] wb_sel_in = 0;

  wire valid_out;
  wire [31:0] pc_plus4_out;
  wire [31:0] alu_result_out;
  wire [31:0] memory_data_out;
  wire [31:0] immediate_out;

  wire [4:0] rd_out;
  wire reg_write_out;
  wire [1:0] wb_sel_out;

  integer passed = 0;
  integer failed = 0;

  // Complete MEM/WB state: 137 bits
  wire [136:0] input_bundle;
  wire [136:0] output_bundle;
  reg [136:0] saved_bundle;

  mem_wb_reg dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),

    .valid_in(valid_in),
    .pc_plus4_in(pc_plus4_in),
    .alu_result_in(alu_result_in),
    .memory_data_in(memory_data_in),
    .immediate_in(immediate_in),
    .rd_in(rd_in),
    .reg_write_in(reg_write_in),
    .wb_sel_in(wb_sel_in),

    .valid_out(valid_out),
    .pc_plus4_out(pc_plus4_out),
    .alu_result_out(alu_result_out),
    .memory_data_out(memory_data_out),
    .immediate_out(immediate_out),
    .rd_out(rd_out),
    .reg_write_out(reg_write_out),
    .wb_sel_out(wb_sel_out)
  );

  always #5 clk = ~clk;

  assign input_bundle = {
    valid_in,
    pc_plus4_in,
    alu_result_in,
    memory_data_in,
    immediate_in,
    rd_in,
    reg_write_in,
    wb_sel_in
  };

  assign output_bundle = {
    valid_out,
    pc_plus4_out,
    alu_result_out,
    memory_data_out,
    immediate_out,
    rd_out,
    reg_write_out,
    wb_sel_out
  };

  task check_state;
    input [136:0] expected;
    input [255:0] test_name;
    begin
      if (output_bundle === expected) begin
        passed = passed + 1;
        $display("PASS: %0s", test_name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", test_name);
        $display("Expected: %h", expected);
        $display("Actual:   %h", output_bundle);
      end
    end
  endtask

  initial begin
    $display("Starting MEM/WB register verification...");

    // Test 1: Reset clears all fields
    @(posedge clk);
    #1;
    check_state(137'd0, "Reset");

    // Test 2: Normal data transfer
    @(negedge clk);
    rst = 0;

    valid_in = 1;
    pc_plus4_in = 32'h00000104;
    alu_result_in = 32'h12345678;
    memory_data_in = 32'hABCDEF01;
    immediate_in = 32'h80000000;
    rd_in = 5'd12;
    reg_write_in = 1;
    wb_sel_in = 2'b01;

    @(posedge clk);
    #1;
    check_state(input_bundle, "Normal transfer");
    saved_bundle = output_bundle;

    // Test 3: Stall retains previous values
    @(negedge clk);
    stall = 1;

    valid_in = 0;
    pc_plus4_in = 32'h00000204;
    alu_result_in = 32'h55555555;
    memory_data_in = 32'h22222222;
    rd_in = 5'd20;
    reg_write_in = 0;

    @(posedge clk);
    #1;
    check_state(saved_bundle, "Stall");

    // Test 4: Flush clears all fields
    @(negedge clk);
    stall = 0;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(137'd0, "Flush");

    // Test 5: Flush overrides Stall
    @(negedge clk);
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(137'd0, "Flush over Stall");

    // Test 6: Reset has highest priority
    @(negedge clk);
    rst = 1;
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(137'd0, "Reset priority");

    // Test 7: Recovery after reset
    @(negedge clk);
    rst = 0;
    stall = 0;
    flush = 0;

    valid_in = 1;
    pc_plus4_in = 32'h00000304;
    alu_result_in = 32'h00000044;
    memory_data_in = 32'h00000022;
    immediate_in = 32'hFFFFF000;
    rd_in = 5'd7;
    reg_write_in = 1;
    wb_sel_in = 2'b10;

    @(posedge clk);
    #1;
    check_state(input_bundle, "Recovery");
    saved_bundle = output_bundle;

    // Test 8: Stall after recovery
    @(negedge clk);
    stall = 1;
    alu_result_in = 32'hDEADBEEF;
    rd_in = 5'd31;
    wb_sel_in = 2'b11;

    @(posedge clk);
    #1;
    check_state(saved_bundle, "Stall after recovery");

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 8 && failed == 0)
      $display("MEM/WB REGISTER TEST PASSED");
    else
      $fatal(1, "MEM/WB REGISTER TEST FAILED");

    $finish;
  end

endmodule
