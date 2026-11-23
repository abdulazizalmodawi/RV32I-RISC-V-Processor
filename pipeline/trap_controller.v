module trap_controller #(
  parameter [31:0] TRAP_VECTOR = 32'h00000100
)(
  input wire clk,
  input wire rst,
  input wire exception_valid,
  input wire [31:0] exception_cause,
  input wire [31:0] exception_pc,
  input wire [31:0] exception_tval,
  input wire trap_return,
  input wire [31:0] return_address,
  // Limited trap-handler CSR write interface.
  input wire mepc_write_valid,
  input wire [31:0] mepc_write_data,
  output reg [31:0] mepc,
  output reg [31:0] mcause,
  output reg [31:0] mtval,
  output reg trap_active,
  output wire trap_redirect,
  output wire [31:0] trap_target,
  output wire trap_flush
);

  assign trap_redirect = exception_valid || trap_return;
  assign trap_target = exception_valid ? TRAP_VECTOR :
                       trap_return ? return_address : 32'd0;
  assign trap_flush = trap_redirect;

  // Priority: reset > exception > trap return / CSR write.
  always @(posedge clk) begin
    if (rst) begin
      mepc <= 32'd0;
      mcause <= 32'd0;
      mtval <= 32'd0;
      trap_active <= 1'b0;
    end else if (exception_valid) begin
      mepc <= exception_pc;
      mcause <= exception_cause;
      mtval <= exception_tval;
      trap_active <= 1'b1;
    end else begin
      // Mask low two bits: this processor supports 32-bit aligned PCs.
      // An unconnected optional input in older TBs is not asserted.
      if (mepc_write_valid === 1'b1 && trap_active)
        mepc <= {mepc_write_data[31:2], 2'b00};
      if (trap_return)
        trap_active <= 1'b0;
    end
  end
endmodule
