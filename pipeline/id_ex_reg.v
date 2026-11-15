module id_ex_reg (
  input wire clk,
  input wire rst,
  input wire stall,
  input wire flush,

  // Data from ID stage
  input wire valid_in,
  input wire [31:0] pc_in,
  input wire [31:0] rs1_data_in,
  input wire [31:0] rs2_data_in,
  input wire [31:0] immediate_in,

  // Register addresses
  input wire [4:0] rs1_in,
  input wire [4:0] rs2_in,
  input wire [4:0] rd_in,

  // Instruction decoding
  input wire [2:0] funct3_in,
  input wire [3:0] alu_sel_in,

  // Control signals
  input wire reg_write_in,
  input wire mem_read_in,
  input wire mem_write_in,
  input wire branch_in,
  input wire jump_in,
  input wire jalr_in,
  input wire alu_src_in,
  input wire alu_a_sel_in,
  input wire [1:0] wb_sel_in,

  // Data to EX stage
  output reg valid_out,
  output reg [31:0] pc_out,
  output reg [31:0] rs1_data_out,
  output reg [31:0] rs2_data_out,
  output reg [31:0] immediate_out,

  // Register addresses
  output reg [4:0] rs1_out,
  output reg [4:0] rs2_out,
  output reg [4:0] rd_out,

  // Instruction decoding
  output reg [2:0] funct3_out,
  output reg [3:0] alu_sel_out,

  // Control signals
  output reg reg_write_out,
  output reg mem_read_out,
  output reg mem_write_out,
  output reg branch_out,
  output reg jump_out,
  output reg jalr_out,
  output reg alu_src_out,
  output reg alu_a_sel_out,
  output reg [1:0] wb_sel_out
);

  // Priority: reset > flush > stall > update

  always @(posedge clk) begin

    if (rst || flush) begin

      valid_out       <= 1'b0;
      pc_out          <= 32'd0;
      rs1_data_out    <= 32'd0;
      rs2_data_out    <= 32'd0;
      immediate_out   <= 32'd0;

      rs1_out         <= 5'd0;
      rs2_out         <= 5'd0;
      rd_out          <= 5'd0;

      funct3_out      <= 3'd0;
      alu_sel_out     <= 4'd0;

      reg_write_out   <= 1'b0;
      mem_read_out    <= 1'b0;
      mem_write_out   <= 1'b0;
      branch_out      <= 1'b0;
      jump_out        <= 1'b0;
      jalr_out        <= 1'b0;
      alu_src_out     <= 1'b0;
      alu_a_sel_out   <= 1'b0;
      wb_sel_out      <= 2'd0;

    end

    else if (!stall) begin

      valid_out       <= valid_in;
      pc_out          <= pc_in;
      rs1_data_out    <= rs1_data_in;
      rs2_data_out    <= rs2_data_in;
      immediate_out   <= immediate_in;

      rs1_out         <= rs1_in;
      rs2_out         <= rs2_in;
      rd_out          <= rd_in;

      funct3_out      <= funct3_in;
      alu_sel_out     <= alu_sel_in;

      reg_write_out   <= reg_write_in;
      mem_read_out    <= mem_read_in;
      mem_write_out   <= mem_write_in;
      branch_out      <= branch_in;
      jump_out        <= jump_in;
      jalr_out        <= jalr_in;
      alu_src_out     <= alu_src_in;
      alu_a_sel_out   <= alu_a_sel_in;
      wb_sel_out      <= wb_sel_in;

    end

  end

endmodule
