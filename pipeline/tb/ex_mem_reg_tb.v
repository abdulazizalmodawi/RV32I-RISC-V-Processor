
module ex_mem_reg_tb;

  reg clk = 0;
  reg rst = 1;
  reg stall = 0;
  reg flush = 0;

  reg valid_in = 0;
  reg [31:0] pc_plus4_in = 0;
  reg [31:0] alu_result_in = 0;
  reg [31:0] rs2_data_in = 0;
  reg [31:0] immediate_in = 0;

  reg [4:0] rd_in = 0;
  reg [2:0] funct3_in = 0;

  reg reg_write_in = 0;
  reg mem_read_in = 0;
  reg mem_write_in = 0;
  reg [1:0] wb_sel_in = 0;

  wire valid_out;
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

  integer passed = 0;
  integer failed = 0;

  // Complete EX/MEM state: 142 bits
  wire [141:0] input_bundle;
  wire [141:0] output_bundle;
  reg [141:0] saved_bundle;

  ex_mem_reg dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),

    .valid_in(valid_in),
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

  always #5 clk = ~clk;

  assign input_bundle = {
    valid_in,
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
  };

  assign output_bundle = {
    valid_out,
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

  task check_state;
    input [141:0] expected;
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
    $display("Starting EX/MEM register verification...");

    // Test 1: Reset
    @(posedge clk);
    #1;
    check_state(142'd0, "Reset");

    // Test 2: Normal transfer
    @(negedge clk);
    rst = 0;

    valid_in = 1;
    pc_plus4_in = 32'h00000104;
    alu_result_in = 32'h12345678;
    rs2_data_in = 32'hABCDEF01;
    immediate_in = 32'hFFFFF800;

    rd_in = 5'd12;
    funct3_in = 3'b010;

    reg_write_in = 1;
    mem_read_in = 1;
    mem_write_in = 0;
    wb_sel_in = 2'b01;

    @(posedge clk);
    #1;
    check_state(input_bundle, "Normal transfer");
    saved_bundle = output_bundle;

    // Test 3: Stall holds previous values
    @(negedge clk);
    stall = 1;

    valid_in = 0;
    pc_plus4_in = 32'h00000204;
    alu_result_in = 32'h55555555;
    rd_in = 5'd20;
    reg_write_in = 0;

    @(posedge clk);
    #1;
    check_state(saved_bundle, "Stall");

    // Test 4: Flush clears the register
    @(negedge clk);
    stall = 0;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(142'd0, "Flush");

    // Test 5: Flush priority over Stall
    @(negedge clk);
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(142'd0, "Flush over Stall");

    // Test 6: Reset highest priority
    @(negedge clk);
    rst = 1;
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check_state(142'd0, "Reset priority");

    // Test 7: Recovery after reset
    @(negedge clk);
    rst = 0;
    stall = 0;
    flush = 0;

    valid_in = 1;
    pc_plus4_in = 32'h00000304;
    alu_result_in = 32'h00000044;
    rs2_data_in = 32'h00000022;
    immediate_in = 32'h80000000;

    rd_in = 5'd7;
    funct3_in = 3'b000;

    reg_write_in = 1;
    mem_read_in = 0;
    mem_write_in = 0;
    wb_sel_in = 2'b00;

    @(posedge clk);
    #1;
    check_state(input_bundle, "Recovery");
    saved_bundle = output_bundle;

    // Test 8: Stall after recovery
    @(negedge clk);
    stall = 1;
    alu_result_in = 32'hDEADBEEF;
    rd_in = 5'd31;

    @(posedge clk);
    #1;
    check_state(saved_bundle, "Stall after recovery");

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 8 && failed == 0)
      $display("EX/MEM REGISTER TEST PASSED");
    else
      $fatal(1, "EX/MEM REGISTER TEST FAILED");

    $finish;
  end

endmodule
