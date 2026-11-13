module next_pc_logic (
  input wire [31:0] pc,
  input wire [31:0] immediate,
  input wire [31:0] rs1_data,
  input wire branch_taken,
  input wire jump,
  input wire jalr,
  output reg [31:0] next_pc
);

  always @(*) begin

    // Default: next sequential instruction
    next_pc = pc + 32'd4;

    // Branch target
    if (branch_taken)
      next_pc = pc + immediate;

    // JAL target
    if (jump)
      next_pc = pc + immediate;

    // JALR target: clear bit 0
    if (jump && jalr)
      next_pc = (rs1_data + immediate) & 32'hFFFFFFFE;

  end

endmodule
