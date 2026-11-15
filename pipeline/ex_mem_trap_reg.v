
module ex_mem_trap_reg (
  input wire clk,
  input wire rst,
  input wire stall,
  input wire flush,

  // Execute stage data
  input wire valid_in,
  input wire [31:0] pc_in,
  input wire [31:0] pc_plus4_in,
  input wire [31:0] alu_result_in,
  input wire [31:0] rs2_data_in,
  input wire [31:0] immediate_in,

  // Destination register
  input wire [4:0] rd_in,

  // Memory information
  input wire [2:0] funct3_in,

  // Control signals
  input wire reg_write_in,
  input wire mem_read_in,
  input wire mem_write_in,
  input wire [1:0] wb_sel_in,

  // Memory stage outputs
  output reg valid_out,
  output reg [31:0] pc_out,
  output reg [31:0] pc_plus4_out,
  output reg [31:0] alu_result_out,
  output reg [31:0] rs2_data_out,
  output reg [31:0] immediate_out,

  output reg [4:0] rd_out,
  output reg [2:0] funct3_out,

  output reg reg_write_out,
  output reg mem_read_out,
  output reg mem_write_out,
  output reg [1:0] wb_sel_out
);

  // Priority: Reset > Flush > Stall > Update
  always @(posedge clk) begin

    if (rst || flush) begin
      valid_out       <= 1'b0;
      pc_out          <= 32'd0;
      pc_plus4_out    <= 32'd0;
      alu_result_out  <= 32'd0;
      rs2_data_out    <= 32'd0;
      immediate_out   <= 32'd0;

      rd_out          <= 5'd0;
      funct3_out      <= 3'd0;

      reg_write_out   <= 1'b0;
      mem_read_out    <= 1'b0;
      mem_write_out   <= 1'b0;
      wb_sel_out      <= 2'b00;
    end

    else if (!stall) begin
      valid_out       <= valid_in;
      pc_out          <= pc_in;
      pc_plus4_out    <= pc_plus4_in;
      alu_result_out  <= alu_result_in;
      rs2_data_out    <= rs2_data_in;
      immediate_out   <= immediate_in;

      rd_out          <= rd_in;
      funct3_out      <= funct3_in;

      reg_write_out   <= reg_write_in;
      mem_read_out    <= mem_read_in;
      mem_write_out   <= mem_write_in;
      wb_sel_out      <= wb_sel_in;
    end

  end

endmodule
