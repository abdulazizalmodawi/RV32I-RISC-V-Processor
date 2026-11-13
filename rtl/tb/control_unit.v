module control_unit (
  input wire [6:0] opcode,

  output reg reg_write,
  output reg alu_src,
  output reg alu_a_sel,
  output reg mem_read,
  output reg mem_write,
  output reg branch,
  output reg jump,
  output reg jalr,
  output reg [1:0] alu_op,
  output reg [1:0] wb_sel,
  output reg valid
);

  // alu_src:   0 = register rs2, 1 = immediate
  // alu_a_sel: 0 = register rs1, 1 = PC
  //
  // alu_op:
  // 00 = ADD
  // 01 = branch comparison
  // 10 = decode funct3/funct7
  //
  // wb_sel:
  // 00 = ALU result
  // 01 = memory data
  // 10 = PC + 4
  // 11 = immediate

  always @(*) begin

    // Safe default values
    reg_write = 1'b0;
    alu_src   = 1'b0;
    alu_a_sel = 1'b0;
    mem_read  = 1'b0;
    mem_write = 1'b0;
    branch    = 1'b0;
    jump      = 1'b0;
    jalr      = 1'b0;
    alu_op    = 2'b00;
    wb_sel    = 2'b00;
    valid     = 1'b1;

    case (opcode)

      // R-Type: register arithmetic
      7'b0110011: begin
        reg_write = 1'b1;
        alu_op    = 2'b10;
      end

      // I-Type: immediate arithmetic
      7'b0010011: begin
        reg_write = 1'b1;
        alu_src   = 1'b1;
        alu_op    = 2'b10;
      end

      // LOAD
      7'b0000011: begin
        reg_write = 1'b1;
        alu_src   = 1'b1;
        mem_read  = 1'b1;
        wb_sel    = 2'b01;
      end

      // STORE
      7'b0100011: begin
        alu_src   = 1'b1;
        mem_write = 1'b1;
      end

      // BRANCH
      7'b1100011: begin
        branch = 1'b1;
        alu_op = 2'b01;
      end

      // JAL
      7'b1101111: begin
        reg_write = 1'b1;
        jump      = 1'b1;
        wb_sel    = 2'b10;
      end

      // JALR
      7'b1100111: begin
        reg_write = 1'b1;
        alu_src   = 1'b1;
        jump      = 1'b1;
        jalr      = 1'b1;
        wb_sel    = 2'b10;
      end

      // LUI
      7'b0110111: begin
        reg_write = 1'b1;
        wb_sel    = 2'b11;
      end

      // AUIPC
      7'b0010111: begin
        reg_write = 1'b1;
        alu_src   = 1'b1;
        alu_a_sel = 1'b1;
      end

      // Unsupported opcode
      default: begin
        valid = 1'b0;
      end

    endcase
  end

endmodule
