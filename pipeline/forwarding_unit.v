module forwarding_unit (
  // Source registers in EX stage
  input wire [4:0] id_ex_rs1,
  input wire [4:0] id_ex_rs2,

  // Destination register in MEM stage
  input wire [4:0] ex_mem_rd,
  input wire ex_mem_valid,
  input wire ex_mem_reg_write,
  input wire ex_mem_mem_read,

  // Destination register in WB stage
  input wire [4:0] mem_wb_rd,
  input wire mem_wb_valid,
  input wire mem_wb_reg_write,

  // Forwarding control outputs
  output reg [1:0] forward_a,
  output reg [1:0] forward_b
);

  // Forwarding selection:
  // 00 = ID/EX register data
  // 01 = MEM/WB writeback data
  // 10 = EX/MEM ALU result
  // 11 = Reserved

  wire ex_mem_can_forward;
  wire mem_wb_can_forward;

  // EX/MEM forwarding is valid for results
  // already available at the end of EX.
  // Loads must wait for memory data.
  assign ex_mem_can_forward =
      ex_mem_valid &&
      ex_mem_reg_write &&
      !ex_mem_mem_read &&
      (ex_mem_rd != 5'd0);

  // MEM/WB forwarding
  assign mem_wb_can_forward =
      mem_wb_valid &&
      mem_wb_reg_write &&
      (mem_wb_rd != 5'd0);

  always @(*) begin

    // Default: use register operands
    forward_a = 2'b00;
    forward_b = 2'b00;

    // Forward operand A
    if (ex_mem_can_forward &&
        (ex_mem_rd == id_ex_rs1)) begin

      forward_a = 2'b10;

    end
    else if (mem_wb_can_forward &&
             (mem_wb_rd == id_ex_rs1) &&
             !(ex_mem_valid &&
               ex_mem_reg_write &&
               (ex_mem_rd != 5'd0) &&
               (ex_mem_rd == id_ex_rs1))) begin

      forward_a = 2'b01;

    end

    // Forward operand B
    if (ex_mem_can_forward &&
        (ex_mem_rd == id_ex_rs2)) begin

      forward_b = 2'b10;

    end
    else if (mem_wb_can_forward &&
             (mem_wb_rd == id_ex_rs2) &&
             !(ex_mem_valid &&
               ex_mem_reg_write &&
               (ex_mem_rd != 5'd0) &&
               (ex_mem_rd == id_ex_rs2))) begin

      forward_b = 2'b01;

    end

  end

endmodule
