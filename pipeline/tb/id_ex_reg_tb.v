timescale 1ns / 1ps

module id_ex_reg_tb;

  reg clk = 0;
  reg rst = 1;
  reg stall = 0;
  reg flush = 0;

  reg valid_in = 0;
  reg [31:0] pc_in = 0;
  reg [31:0] rs1_data_in = 0;
  reg [31:0] rs2_data_in = 0;
  reg [31:0] immediate_in = 0;

  reg [4:0] rs1_in = 0;
  reg [4:0] rs2_in = 0;
  reg [4:0] rd_in = 0;

  reg [2:0] funct3_in = 0;
  reg [3:0] alu_sel_in = 0;

  reg reg_write_in = 0;
  reg mem_read_in = 0;
  reg mem_write_in = 0;
  reg branch_in = 0;
  reg jump_in = 0;
  reg jalr_in = 0;
  reg alu_src_in = 0;
  reg alu_a_sel_in = 0;
  reg [1:0] wb_sel_in = 0;

  wire valid_out;
  wire [31:0] pc_out;
  wire [31:0] rs1_data_out;
  wire [31:0] rs2_data_out;
  wire [31:0] immediate_out;

  wire [4:0] rs1_out;
  wire [4:0] rs2_out;
  wire [4:0] rd_out;

  wire [2:0] funct3_out;
  wire [3:0] alu_sel_out;

  wire reg_write_out;
  wire mem_read_out;
  wire mem_write_out;
  wire branch_out;
  wire jump_out;
  wire jalr_out;
  wire alu_src_out;
  wire alu_a_sel_out;
  wire [1:0] wb_sel_out;

  integer passed = 0;
  integer failed = 0;

  // Complete ID/EX state: 161 bits
  wire [160:0] input_bundle;
  wire [160:0] output_bundle;
  reg [160:0] saved_bundle;

  id_ex_reg dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),

    .valid_in(valid_in),
    .pc_in(pc_in),
    .rs1_data_in(rs1_data_in),
    .rs2_data_in(rs2_data_in),
    .immediate_in(immediate_in),

    .rs1_in(rs1_in),
    .rs2_in(rs2_in),
    .rd_in(rd_in),

    .funct3_in(funct3_in),
    .alu_sel_in(alu_sel_in),

    .reg_write_in(reg_write_in),
    .mem_read_in(mem_read_in),
    .mem_write_in(mem_write_in),
    .branch_in(branch_in),
    .jump_in(jump_in),
    .jalr_in(jalr_in),
    .alu_src_in(alu_src_in),
    .alu_a_sel_in(alu_a_sel_in),
    .wb_sel_in(wb_sel_in),

    .valid_out(valid_out),
    .pc_out(pc_out),
    .rs1_data_out(rs1_data_out),
    .rs2_data_out(rs2_data_out),
    .immediate_out(immediate_out),

    .rs1_out(rs1_out),
    .rs2_out(rs2_out),
    .rd_out(rd_out),

    .funct3_out(funct3_out),
    .alu_sel_out(alu_sel_out),

    .reg_write_out(reg_write_out),
    .mem_read_out(mem_read_out),
    .mem_write_out(mem_write_out),
    .branch_out(branch_out),
    .jump_out(jump_out),
    .jalr_out(jalr_out),
    .alu_src_out(alu_src_out),
    .alu_a_sel_out(alu_a_sel_out),
    .wb_sel_out(wb_sel_out)
  );

  always #5 clk = ~clk;

  assign input_bundle = {
    valid_in, pc_in, rs1_data_in,
    rs2_data_in, immediate_in,
    rs1_in, rs2_in, rd_in,
    funct3_in, alu_sel_in,
    reg_write_in, mem_read_in, mem_write_in,
    branch_in, jump_in, jalr_in,
    alu_src_in, alu_a_sel_in, wb_sel_in
  };

  assign output_bundle = {
    valid_out, pc_out, rs1_data_out,
    rs2_data_out, immediate_out,
    rs1_out, rs2_out, rd_out,
    funct3_out, alu_sel_out,
    reg_write_out, mem_read_out, mem_write_out,
    branch_out, jump_out, jalr_out,
    alu_src_out, alu_a_sel_out, wb_sel_out
  };

  task check_state;
    input [160:0] expected;
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
    $display("Starting ID/EX register verification...");

    // Test 1: Reset clears every field
    @(posedge clk);
    #1;
    check_state(161'd0, "Reset");

    // Test 2: Transfer all fields
    @(negedge clk);
    rst = 0;

    valid_in = 1;
    pc_in = 32'h00000100;
    rs1_data_in = 32'h12345678;
    rs2_data_in = 32'hABCDEF01;
    immediate_in = 32'hFFFFFFFC;

    rs1_in = 5'd3;
    rs2_in = 5'd7;
    rd_in = 5'd12;

    funct3_in = 3'b101;
    alu_sel_in = 4'd7;

    reg_write_in = 1;
    mem_read_in = 1;
    mem_write_in = 0;
    branch_in = 1;
    jump_in = 1;
    jalr_in = 1;
    alu_src_in = 1;
    alu_a_sel_in = 1;
    wb_sel_in = 2'b10;

    @(posedge clk);
    #1;
    check_state(input_bundle, "Normal transfer");
    saved_bundle = output_bundle;

    // Test 3: Stall holds previous values
    @(negedge clk);
    stall = 1;
    valid_in = 0;
    pc_in = 32'h00000200;
    rs1_data_in = 32'h55555555;
    reg_write_in = 0;
    wb_sel_in = 2'b01;

    @(posedge clk);
    #1;
    check_state(saved_bundle, "Stall");

    // Test 4: Flush clears every field
    @(negedge clk);
    stall = 0;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(161'd0, "Flush");

    // Test 5: Flush has priority over Stall
    @(negedge clk);
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(161'd0, "Flush over Stall");

    // Test 6: Reset has highest priority
    @(negedge clk);
    rst = 1;
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(161'd0, "Reset priority");

    // Test 7: Recovery after reset
    @(negedge clk);
    rst = 0;
    stall = 0;
    flush = 0;

    valid_in = 1;
    pc_in = 32'h00000300;
    rs1_data_in = 32'h00000011;
    rs2_data_in = 32'h00000022;
    immediate_in = 32'h00000044;

    rs1_in = 5'd1;
    rs2_in = 5'd2;
    rd_in = 5'd3;

    funct3_in = 3'b010;
    alu_sel_in = 4'd0;

    reg_write_in = 1;
    mem_read_in = 0;
    mem_write_in = 0;
    branch_in = 0;
    jump_in = 0;
    jalr_in = 0;
    alu_src_in = 1;
    alu_a_sel_in = 0;
    wb_sel_in = 2'b00;

    @(posedge clk);
    #1;
    check_state(input_bundle, "Recovery");
    saved_bundle = output_bundle;

    // Test 8: Stall after recovery
    @(negedge clk);
    stall = 1;
    pc_in = 32'h00000400;
    rd_in = 5'd20;

    @(posedge clk);
    #1;
    check_state(saved_bundle, "Stall after recovery");

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 8 && failed == 0)
      $display("ID/EX REGISTER TEST PASSED");
    else
      $fatal(1, "ID/EX REGISTER TEST FAILED");

    $finish;
  end

endmodule
