module branch_control (
  input wire branch_en,
  input wire [2:0] funct3,
  input wire [31:0] rs1_data,
  input wire [31:0] rs2_data,
  output reg branch_taken,
  output reg valid
);

  always @(*) begin
    branch_taken = 1'b0;
    valid = 1'b1;

    case (funct3)

      // BEQ: Branch if equal
      3'b000:
        branch_taken = (rs1_data == rs2_data);

      // BNE: Branch if not equal
      3'b001:
        branch_taken = (rs1_data != rs2_data);

      // BLT: Signed less than
      3'b100:
        branch_taken = ($signed(rs1_data) <
                        $signed(rs2_data));

      // BGE: Signed greater than or equal
      3'b101:
        branch_taken = ($signed(rs1_data) >=
                        $signed(rs2_data));

      // BLTU: Unsigned less than
      3'b110:
        branch_taken = (rs1_data < rs2_data);

      // BGEU: Unsigned greater than or equal
      3'b111:
        branch_taken = (rs1_data >= rs2_data);

      // Unsupported branch condition
      default: begin
        branch_taken = 1'b0;
        valid = 1'b0;
      end

    endcase

    // Disable branching when branch_en is low
    if (!branch_en)
      branch_taken = 1'b0;

  end

endmodule
