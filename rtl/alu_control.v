module alu_control (
  input wire [6:0] opcode,
  input wire [1:0] alu_op,
  input wire [2:0] funct3,
  input wire [6:0] funct7,
  output reg [3:0] alu_sel,
  output reg valid
);

  // ALU operation codes
  // 0 = ADD, 1 = SUB, 2 = AND
  // 3 = OR,  4 = XOR, 5 = SLL
  // 6 = SRL, 7 = SRA, 8 = SLT
  // 9 = SLTU

  always @(*) begin
    alu_sel = 4'd0;
    valid = 1'b1;

    case (alu_op)

      // Default addition
      2'b00: begin
        alu_sel = 4'd0;
      end

      // Branch comparisons
      2'b01: begin
        if (opcode == 7'b1100011) begin
          case (funct3)
            3'b000, 3'b001: alu_sel = 4'd1;
            3'b100, 3'b101: alu_sel = 4'd8;
            3'b110, 3'b111: alu_sel = 4'd9;
            default: valid = 1'b0;
          endcase
        end else begin
          valid = 1'b0;
        end
      end

      // Register and immediate arithmetic
      2'b10: begin
        case (opcode)

          // R-Type
          7'b0110011: begin
            case ({funct7, funct3})
              {7'b0000000, 3'b000}: alu_sel = 4'd0;
              {7'b0100000, 3'b000}: alu_sel = 4'd1;
              {7'b0000000, 3'b111}: alu_sel = 4'd2;
              {7'b0000000, 3'b110}: alu_sel = 4'd3;
              {7'b0000000, 3'b100}: alu_sel = 4'd4;
              {7'b0000000, 3'b001}: alu_sel = 4'd5;
              {7'b0000000, 3'b101}: alu_sel = 4'd6;
              {7'b0100000, 3'b101}: alu_sel = 4'd7;
              {7'b0000000, 3'b010}: alu_sel = 4'd8;
              {7'b0000000, 3'b011}: alu_sel = 4'd9;
              default: valid = 1'b0;
            endcase
          end

          // I-Type
          7'b0010011: begin
            case (funct3)
              3'b000: alu_sel = 4'd0;
              3'b111: alu_sel = 4'd2;
              3'b110: alu_sel = 4'd3;
              3'b100: alu_sel = 4'd4;
              3'b010: alu_sel = 4'd8;
              3'b011: alu_sel = 4'd9;

              3'b001: begin
                if (funct7 == 7'b0000000)
                  alu_sel = 4'd5;
                else
                  valid = 1'b0;
              end

              3'b101: begin
                if (funct7 == 7'b0000000)
                  alu_sel = 4'd6;
                else if (funct7 == 7'b0100000)
                  alu_sel = 4'd7;
                else
                  valid = 1'b0;
              end

              default: valid = 1'b0;
            endcase
          end

          default: valid = 1'b0;

        endcase
      end

      default: valid = 1'b0;

    endcase
  end

endmodule
