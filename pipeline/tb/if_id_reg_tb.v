

module if_id_reg_tb;

  reg clk = 0;
  reg rst = 1;
  reg stall = 0;
  reg flush = 0;

  reg [31:0] pc_in = 0;
  reg [31:0] instruction_in = 32'h00000013;

  wire [31:0] pc_out;
  wire [31:0] instruction_out;

  integer passed = 0;
  integer failed = 0;

  if_id_reg dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),
    .pc_in(pc_in),
    .instruction_in(instruction_in),
    .pc_out(pc_out),
    .instruction_out(instruction_out)
  );

  always #5 clk = ~clk;

  task check;
    input [31:0] actual;
    input [31:0] expected;
    begin
      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS expected=%h actual=%h",
                 expected, actual);
      end else begin
        failed = failed + 1;
        $display("FAIL expected=%h actual=%h",
                 expected, actual);
      end
    end
  endtask

  initial begin
    $display("Starting IF/ID register verification...");

    // Test 1: Reset
    @(posedge clk);
    #1;
    check(pc_out, 32'd0);
    check(instruction_out, 32'h00000013);

    // Test 2: Normal update
    @(negedge clk);
    rst = 0;
    pc_in = 32'd100;
    instruction_in = 32'h00500093;

    @(posedge clk);
    #1;
    check(pc_out, 32'd100);
    check(instruction_out, 32'h00500093);

    // Test 3: Stall holds previous values
    @(negedge clk);
    stall = 1;
    pc_in = 32'd104;
    instruction_in = 32'h00700113;

    @(posedge clk);
    #1;
    check(pc_out, 32'd100);
    check(instruction_out, 32'h00500093);

    // Test 4: Flush inserts NOP
    @(negedge clk);
    stall = 0;
    flush = 1;

    @(posedge clk);
    #1;
    check(pc_out, 32'd0);
    check(instruction_out, 32'h00000013);

    // Test 5: Flush has priority over Stall
    @(negedge clk);
    stall = 1;
    flush = 1;
    pc_in = 32'd200;
    instruction_in = 32'h00100213;

    @(posedge clk);
    #1;
    check(pc_out, 32'd0);
    check(instruction_out, 32'h00000013);

    // Test 6: Reset has highest priority
    @(negedge clk);
    rst = 1;
    stall = 1;
    flush = 1;

    @(posedge clk);
    #1;
    check(pc_out, 32'd0);
    check(instruction_out, 32'h00000013);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 12 && failed == 0)
      $display("IF/ID REGISTER TEST PASSED");
    else
      $fatal(1, "IF/ID REGISTER TEST FAILED");

    $finish;
  end

endmodule
