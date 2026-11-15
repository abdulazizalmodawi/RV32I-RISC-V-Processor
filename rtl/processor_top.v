module processor_top (
  input wire clk,
  input wire rst,
  output wire [31:0] pc,
  output wire [31:0] instruction,
  output wire execution_valid
);

  wire instruction_valid;
  wire control_valid;
  wire alu_valid;
  wire branch_valid;
  wire memory_valid;
  wire encoding_valid;
  wire target_alignment_valid;
  wire control_transfer;

  wire reg_write;
  wire alu_src;
  wire alu_a_sel;
  wire mem_read;
  wire mem_write;
  wire branch;
  wire jump;
  wire jalr;
  wire [1:0] alu_op;
  wire [1:0] wb_sel;

  wire [3:0] alu_sel;
  wire [31:0] immediate;
  wire [31:0] rs1_data;
  wire [31:0] rs2_data;
  wire [31:0] alu_a;
  wire [31:0] alu_b;
  wire [31:0] alu_result;
  wire [31:0] memory_data;
  wire [31:0] writeback_data;
  wire [31:0] next_pc;

  wire branch_taken;
  wire decode_valid;
  wire register_write_enable;
  wire memory_read_enable;
  wire memory_write_enable;

  // Instruction fetch
  instruction_memory imem (
    .pc(pc),
    .instruction(instruction),
    .valid(instruction_valid)
  );

  // Main instruction decoding
  control_unit control (
    .opcode(instruction[6:0]),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .alu_a_sel(alu_a_sel),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .alu_op(alu_op),
    .wb_sel(wb_sel),
    .valid(control_valid)
  );

  // Immediate extraction
  immediate_generator imm_gen (
    .instruction(instruction),
    .immediate(immediate)
  );

  // ALU operation decoding
  alu_control alu_decoder (
    .opcode(instruction[6:0]),
    .alu_op(alu_op),
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),
    .alu_sel(alu_sel),
    .valid(alu_valid)
  );

  // Register file
  register_file rf (
    .clk(clk),
    .rst(rst),
    .reg_write(register_write_enable),
    .rs1(instruction[19:15]),
    .rs2(instruction[24:20]),
    .rd(instruction[11:7]),
    .write_data(writeback_data),
    .read_data1(rs1_data),
    .read_data2(rs2_data)
  );

  // ALU operand selection
  assign alu_a = alu_a_sel ? pc : rs1_data;
  assign alu_b = alu_src ? immediate : rs2_data;

  // ALU execution
  alu alu_core (
    .a(alu_a),
    .b(alu_b),
    .alu_op(alu_sel),
    .result(alu_result)
  );

  // Branch comparison
  branch_control branch_unit (
    .branch_en(branch),
    .funct3(instruction[14:12]),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .branch_taken(branch_taken),
    .valid(branch_valid)
  );

  // Next instruction address
  next_pc_logic next_pc_unit (
    .pc(pc),
    .immediate(immediate),
    .rs1_data(rs1_data),
    .branch_taken(branch_taken),
    .jump(jump),
    .jalr(jalr),
    .next_pc(next_pc)
  );

  // Validate JALR funct3 and FENCE funct3.
  // Only standard FENCE (funct3=000) is modeled.
  // FENCE.I (funct3=001) is not supported.
  assign encoding_valid =
      (!jalr || instruction[14:12] == 3'b000) &&
      ((instruction[6:0] != 7'b0001111) ||
       (instruction[14:12] == 3'b000));

  // Validate taken branch and jump target alignment.
  // RV32I without compressed instructions requires
  // 4-byte instruction address alignment.
  assign control_transfer =
      jump || (branch && branch_taken);

  assign target_alignment_valid =
      !control_transfer ||
      (next_pc[1:0] == 2'b00);

  // Instruction validation
  assign decode_valid =
      instruction_valid &&
      control_valid &&
      alu_valid &&
      encoding_valid &&
      (!branch || branch_valid) &&
      target_alignment_valid;

  // Memory access enables
  assign memory_read_enable =
      mem_read && decode_valid;

  assign memory_write_enable =
      mem_write && decode_valid;

  // Data memory
  data_memory dmem (
    .clk(clk),
    .mem_read(memory_read_enable),
    .mem_write(memory_write_enable),
    .funct3(instruction[14:12]),
    .address(alu_result),
    .write_data(rs2_data),
    .read_data(memory_data),
    .valid(memory_valid)
  );

  // Prevent architectural updates on invalid operations
  assign execution_valid =
      decode_valid && memory_valid;

  assign register_write_enable =
      reg_write && execution_valid;

  // Writeback selection
  assign writeback_data =
      (wb_sel == 2'b00) ? alu_result :
      (wb_sel == 2'b01) ? memory_data :
      (wb_sel == 2'b10) ? (pc + 32'd4) :
                          immediate;

  // Program counter
  program_counter pc_reg (
    .clk(clk),
    .rst(rst),
    .pc_write(execution_valid),
    .next_pc(next_pc),
    .pc(pc)
  );

endmodule
