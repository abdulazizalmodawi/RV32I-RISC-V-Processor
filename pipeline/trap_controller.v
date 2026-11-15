
module trap_controller #(
  parameter [31:0] TRAP_VECTOR = 32'h00000100
)(
  input wire clk,
  input wire rst,

  // Exception information from detection unit
  input wire exception_valid,
  input wire [31:0] exception_cause,
  input wire [31:0] exception_pc,
  input wire [31:0] exception_tval,

  // Trap return request (simplified interface)
  input wire trap_return,
  input wire [31:0] return_address,

  // Registered trap information
  output reg [31:0] mepc,
  output reg [31:0] mcause,
  output reg [31:0] mtval,
  output reg trap_active,

  // Control-flow outputs
  output wire trap_redirect,
  output wire [31:0] trap_target,
  output wire trap_flush
);

  // Exception has priority over trap return.
  // Combinational redirect is available during
  // the same cycle as the exception request.

  assign trap_redirect = exception_valid || trap_return;

  assign trap_target =
      exception_valid ? TRAP_VECTOR :
      trap_return ? return_address :
      32'd0;

  assign trap_flush = trap_redirect;

  // Save exception context at the rising clock edge.
  always @(posedge clk) begin
    if (rst) begin
      mepc        <= 32'd0;
      mcause      <= 32'd0;
      mtval       <= 32'd0;
      trap_active <= 1'b0;
    end
    else if (exception_valid) begin
      mepc        <= exception_pc;
      mcause      <= exception_cause;
      mtval       <= exception_tval;
      trap_active <= 1'b1;
    end
    else if (trap_return) begin
      trap_active <= 1'b0;
    end
  end

endmodule
