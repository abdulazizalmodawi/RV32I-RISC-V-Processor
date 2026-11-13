`timescale 1ns / 1ps

module data_memory_tb;

  reg clk = 0;
  reg mem_read = 0;
  reg mem_write = 0;
  reg [2:0] funct3 = 0;
  reg [31:0] address = 0;
  reg [31:0] write_data = 0;

  wire [31:0] read_data;
  wire valid;

  integer passed = 0;
  integer failed = 0;

  data_memory dut (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .funct3(funct3),
    .address(address),
    .write_data(write_data),
    .read_data(read_data),
    .valid(valid)
  );

  always #5 clk = ~clk;

  task check_read;
    input [31:0] addr;
    input [2:0] operation;
    input [31:0] expected_data;
    input expected_valid;
    begin
      @(negedge clk);
      mem_read = 1;
      mem_write = 0;
      address = addr;
      funct3 = operation;
      #1;

      if (read_data === expected_data &&
          valid === expected_valid) begin
        passed = passed + 1;
        $display("PASS READ: addr=%h data=%h valid=%b",
                 address, read_data, valid);
      end else begin
        failed = failed + 1;
        $display("FAIL READ: addr=%h expected=%h/%b actual=%h/%b",
                 address, expected_data, expected_valid,
                 read_data, valid);
      end

      mem_read = 0;
    end
  endtask

  task check_write;
    input [31:0] addr;
    input [2:0] operation;
    input [31:0] data;
    input expected_valid;
    begin
      @(negedge clk);
      mem_read = 0;
      mem_write = 1;
      address = addr;
      funct3 = operation;
      write_data = data;
      #1;

      if (valid === expected_valid) begin
        passed = passed + 1;
        $display("PASS WRITE: addr=%h valid=%b",
                 address, valid);
      end else begin
        failed = failed + 1;
        $display("FAIL WRITE: addr=%h expected_valid=%b actual=%b",
                 address, expected_valid, valid);
      end

      @(posedge clk);
      #1;
      mem_write = 0;
    end
  endtask

  initial begin
    $display("Starting Data Memory verification...");

    // Initial memory contents
    check_read(32'd0, 3'b010, 32'h00000000, 1);

    // Write and read a full word
    check_write(32'd0, 3'b010, 32'hA1B2C3D4, 1);
    check_read(32'd0, 3'b010, 32'hA1B2C3D4, 1);

    // Signed and unsigned byte reads
    check_read(32'd0, 3'b000, 32'hFFFFFFD4, 1);
    check_read(32'd0, 3'b100, 32'h000000D4, 1);

    // Signed and unsigned halfword reads
    check_read(32'd0, 3'b001, 32'hFFFFC3D4, 1);
    check_read(32'd0, 3'b101, 32'h0000C3D4, 1);

    // Read most significant byte
    check_read(32'd3, 3'b000, 32'hFFFFFFA1, 1);

    // Store byte and verify word
    check_write(32'd1, 3'b000, 32'h000000FF, 1);
    check_read(32'd0, 3'b010, 32'hA1B2FFD4, 1);

    // Store halfword and verify word
    check_write(32'd2, 3'b001, 32'h00001234, 1);
    check_read(32'd0, 3'b010, 32'h1234FFD4, 1);
    check_read(32'd2, 3'b101, 32'h00001234, 1);

    // Last valid word in memory
    check_write(32'd1020, 3'b010, 32'hDEADBEEF, 1);
    check_read(32'd1020, 3'b010, 32'hDEADBEEF, 1);

    // Misaligned reads must be rejected
    check_read(32'd2, 3'b010, 32'd0, 0);
    check_read(32'd1, 3'b001, 32'd0, 0);

    // Out-of-range read
    check_read(32'd1024, 3'b010, 32'd0, 0);

    // Misaligned write must be rejected
    check_write(32'd1, 3'b001, 32'h00005678, 0);

    // Verify memory was not modified
    check_read(32'd0, 3'b010, 32'h1234FFD4, 1);

    // Out-of-range write
    check_write(32'd1024, 3'b010, 32'hFFFFFFFF, 0);

    // Unsupported load and store types
    check_read(32'd0, 3'b011, 32'd0, 0);
    check_write(32'd0, 3'b100, 32'hFFFFFFFF, 0);

    // Check a different untouched location
    check_read(32'd4, 3'b010, 32'd0, 1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 24 && failed == 0)
      $display("DATA MEMORY VERIFICATION PASSED");
    else
      $fatal(1, "DATA MEMORY VERIFICATION FAILED");

    $finish;
  end

endmodule
