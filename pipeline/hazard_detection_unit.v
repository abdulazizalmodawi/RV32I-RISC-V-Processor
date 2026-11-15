module hazard_detection_unit (
  // Instruction currently in Decode stage
  input wire if_id_valid,
  input wire [6:0] if_id_opcode,
  input wire [4:0] if_id_rs1,
  input wire [4:0] if_id_rs2,

  // Instruction currently in Execute stage
  input wire id_ex_valid,
  input wire id_ex_mem_read,
  input wire [4:0] id_ex_rd,

  // Pipeline control outputs
  output reg pc_write,
  output reg if_id_write,
  output reg id_ex_flush,
  output reg stall
);

  wire uses_rs1;
  wire uses_rs2;
  wire load_use_hazard;

  // Decode-stage source register usage
  assign uses_rs1 =
      (if_id_opcode == 7'b0110011) || // R-Type
      (if_id_opcode == 7'b0010011) || // I-Type ALU
      (if_id_opcode == 7'b0000011) || // LOAD
      (if_id_opcode == 7'b0100011) || // STORE
      (if_id_opcode == 7'b1100011) || // BRANCH
      (if_id_opcode == 7'b1100111);   // JALR

  assign uses_rs2 =
      (if_id_opcode == 7'b0110011) || // R-Type
      (if_id_opcode == 7'b0100011) || // STORE
      (if_id_opcode == 7'b1100011);   // BRANCH

  // Detect Load-Use Hazard
  assign load_use_hazard =
      if_id_valid &&
      id_ex_valid &&
      id_ex_mem_read &&
      (id_ex_rd != 5'd0) &&
      (
        (uses_rs1 && (id_ex_rd == if_id_rs1)) ||
        (uses_rs2 && (id_ex_rd == if_id_rs2))
      );

  always @(*) begin

    // Normal pipeline operation
    pc_write   = 1'b1;
    if_id_write = 1'b1;
    id_ex_flush = 1'b0;
    stall       = 1'b0;

    if (load_use_hazard) begin

      // Keep the current PC
      pc_write = 1'b0;

      // Hold the instruction in IF/ID
      if_id_write = 1'b0;

      // Insert a bubble into ID/EX
      id_ex_flush = 1'b1;

      // Report a pipeline stall
      stall = 1'b1;

    end

  end

endmodule
