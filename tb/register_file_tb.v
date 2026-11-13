`timescale 1ns / 1ps

module register_file_tb;

  reg clk = 0;
  reg rst = 0;
  reg reg_write = 0;
  reg [4:0] rs1 = 0;
  reg [4:0] rs2 = 0;
  reg [4:0] rd = 0;
  reg [31:0] write_data = 0;

  wire [31:0] read_data1;
  wire [31:0] read_data2;

  integer passed = 0;
  integer failed = 0;

  register_file dut (
    .clk(clk),
    .rst(rst),
    .reg_write(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(write_data),
    .read_data1(read_data1),
    .read_data2(read_data2)
  );

  always #5 clk = ~clk;

  task check;
    input [31:0] actual;
    input [31:0] expected;
    begin
      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: expected=%h actual=%h",
                 expected, actual);
      end else begin
        failed = failed + 1;
        $display("FAIL: expected=%h actual=%h",
                 expected, actual);
      end
    end
  endtask

  task write_reg;
    input [4:0] address;
    input [31:0] data;
    begin
      @(negedge clk);
      reg_write = 1;
      rd = address;
      write_data = data;
      @(posedge clk);
      #1;
      reg_write = 0;
    end
  endtask

  initial begin
    $display("Starting Register File verification...");

    // Reset all registers
    @(negedge clk);
    rst = 1;
    @(posedge clk);
    #1;
    rst = 0;

    // Test 1: x0 always reads zero
    rs1 = 0;
    #1;
    check(read_data1, 32'd0);

    // Test 2: Write and read x1
    write_reg(5'd1, 32'h12345678);
    rs1 = 1;
    #1;
    check(read_data1, 32'h12345678);

    // Test 3: Write and read x2
    write_reg(5'd2, 32'hABCDEF12);
    rs2 = 2;
    #1;
    check(read_data2, 32'hABCDEF12);

    // Test 4: Two independent read ports
    rs1 = 1;
    rs2 = 2;
    #1;
    check(read_data1, 32'h12345678);

    // Test 5: Second read port
    check(read_data2, 32'hABCDEF12);

    // Test 6: x0 cannot be modified
    write_reg(5'd0, 32'hFFFFFFFF);
    rs1 = 0;
    #1;
    check(read_data1, 32'd0);

    // Test 7: Write to x31
    write_reg(5'd31, 32'hDEADBEEF);
    rs1 = 31;
    #1;
    check(read_data1, 32'hDEADBEEF);

    // Test 8: Writing disabled
    @(negedge clk);
    reg_write = 0;
    rd = 1;
    write_data = 32'hFFFFFFFF;
    @(posedge clk);
    #1;
    rs1 = 1;
    #1;
    check(read_data1, 32'h12345678);

    // Test 9: Overwrite existing register
    write_reg(5'd1, 32'h87654321);
    rs1 = 1;
    #1;
    check(read_data1, 32'h87654321);

    // Test 10: Reset clears stored values
    @(negedge clk);
    rst = 1;
    @(posedge clk);
    #1;
    rst = 0;
    rs1 = 1;
    #1;
    check(read_data1, 32'd0);

    // Test 11: Reset clears x31
    rs2 = 31;
    #1;
    check(read_data2, 32'd0);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (failed == 0 && passed == 11)
      $display("REGISTER FILE VERIFICATION PASSED");
    else
      $fatal(1, "REGISTER FILE VERIFICATION FAILED");

    $finish;
  end

endmodule
