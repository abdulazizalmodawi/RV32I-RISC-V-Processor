module program_counter (
  input wire clk,
  input wire rst,
  input wire pc_write,
  input wire [31:0] next_pc,
  output reg [31:0] pc
);

  // Synchronous, active-high reset
  // PC advances only when pc_write is enabled

  always @(posedge clk) begin
    if (rst)
      pc <= 32'h00000000;
    else if (pc_write)
      pc <= next_pc;
  end

endmodule
