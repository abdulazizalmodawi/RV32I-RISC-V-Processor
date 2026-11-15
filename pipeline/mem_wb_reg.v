module mem_wb_reg (
  input wire clk,
  input wire rst,
  input wire stall,
  input wire flush,

  // Data from Memory stage
  input wire valid_in,
  input wire [31:0] pc_plus4_in,
  input wire [31:0] alu_result_in,
  input wire [31:0] memory_data_in,
  input wire [31:0] immediate_in,

  // Destination register
  input wire [4:0] rd_in,

  // Writeback control signals
  input wire reg_write_in,
  input wire [1:0] wb_sel_in,

  // Data to Writeback stage
  output reg valid_out,
  output reg [31:0] pc_plus4_out,
  output reg [31:0] alu_result_out,
  output reg [31:0] memory_data_out,
  output reg [31:0] immediate_out,

  // Destination register
  output reg [4:0] rd_out,

  // Writeback control signals
  output reg reg_write_out,
  output reg [1:0] wb_sel_out
);

  // Priority:
  // Reset > Flush > Stall > Normal Update

  always @(posedge clk) begin

    if (rst || flush) begin

      valid_out       <= 1'b0;
      pc_plus4_out    <= 32'd0;
      alu_result_out  <= 32'd0;
      memory_data_out <= 32'd0;
      immediate_out   <= 32'd0;

      rd_out          <= 5'd0;

      // Disable register writes
      reg_write_out   <= 1'b0;
      wb_sel_out      <= 2'b00;

    end

    else if (!stall) begin

      // Transfer memory-stage results
      valid_out       <= valid_in;
      pc_plus4_out    <= pc_plus4_in;
      alu_result_out  <= alu_result_in;
      memory_data_out <= memory_data_in;
      immediate_out   <= immediate_in;

      rd_out          <= rd_in;

      // Transfer writeback control signals
      reg_write_out   <= reg_write_in;
      wb_sel_out      <= wb_sel_in;

    end

    // Stall: retain previous values

  end

endmodule
