module processor_pipeline_trap_top (
  input wire clk,
  input wire rst
);

  // =========================================================
  // 1. INSTRUCTION FETCH (IF)
  // =========================================================

  reg [31:0] pc;
  wire [31:0] if_instruction;
  wire if_instruction_valid;

  wire hazard_pc_write;
  wire hazard_if_id_write;
  wire hazard_id_ex_flush;
  wire hazard_stall;

  wire pc_redirect;
  wire branch_if_id_flush;
  wire branch_id_ex_flush;

  wire [31:0] ex_next_pc;
  // Exception detection signals
  wire exception_valid;
  wire [31:0] exception_cause;
  wire [31:0] exception_pc;
  wire [31:0] exception_tval;
  wire [1:0] exception_stage;
  
  // Trap controller signals
  wire [31:0] trap_mepc;
  wire [31:0] trap_mcause;
  wire [31:0] trap_mtval;
  wire trap_active;
  wire trap_redirect;
  wire [31:0] trap_target;
  wire trap_flush;

  // Experimental MRET support (not a complete privileged ISA).
  localparam [31:0] MRET_INSTRUCTION = 32'h30200073;
  wire id_mret;
  wire trap_return_request;
  wire [31:0] trap_return_address;

  assign id_mret = id_valid &&
                   (id_instruction == MRET_INSTRUCTION);
  // This demonstration skips the faulting 32-bit instruction.
  // Standard MRET returns to mepc; full CSR software handling is future work.
  assign trap_return_address = trap_mepc + 32'd4;
  assign trap_return_request =
      id_mret && trap_active && !hazard_stall &&
      !pc_redirect && !exception_valid;


  instruction_memory imem (
    .pc(pc),
    .instruction(if_instruction),
    .valid(if_instruction_valid)
  );

  // Branch redirect has priority over load-use stalls.
  always @(posedge clk) begin
    if (rst)
      pc <= 32'd0;
    else if (trap_redirect)
      pc <= trap_target;
    else if (pc_redirect)
      pc <= ex_next_pc;
    else if (hazard_pc_write)
      pc <= pc + 32'd4;
  end

  // =========================================================
  // 2. IF/ID PIPELINE REGISTERS
  // =========================================================

  wire [31:0] id_pc;
  wire [31:0] id_instruction;
  wire id_valid;

  if_id_reg if_id_stage (
    .clk(clk),
    .rst(rst),
    .stall(!hazard_if_id_write),
    .flush(branch_if_id_flush || trap_flush),
    .pc_in(pc),
    .instruction_in(if_instruction),
    .pc_out(id_pc),
    .instruction_out(id_instruction)
  );

  if_id_valid_reg if_id_valid_stage (
    .clk(clk),
    .rst(rst),
    .stall(!hazard_if_id_write),
    .flush(branch_if_id_flush || trap_flush),
    .valid_in(if_instruction_valid),
    .valid_out(id_valid)
  );

  // =========================================================
  // 3. INSTRUCTION DECODE (ID)
  // =========================================================

  wire [6:0] id_opcode = id_instruction[6:0];
  wire [4:0] id_rs1 = id_instruction[19:15];
  wire [4:0] id_rs2 = id_instruction[24:20];
  wire [4:0] id_rd = id_instruction[11:7];
  wire [2:0] id_funct3 = id_instruction[14:12];
  wire [6:0] id_funct7 = id_instruction[31:25];

  wire [31:0] id_immediate;
  wire [31:0] rf_read1;
  wire [31:0] rf_read2;
  wire [31:0] id_rs1_data;
  wire [31:0] id_rs2_data;

  wire id_reg_write;
  wire id_alu_src;
  wire id_alu_a_sel;
  wire id_mem_read;
  wire id_mem_write;
  wire id_branch;
  wire id_jump;
  wire id_jalr;
  wire [1:0] id_alu_op;
  wire [1:0] id_wb_sel;
  wire id_control_valid;

  wire [3:0] id_alu_sel;
  wire id_alu_valid;

  wire wb_valid;
  wire wb_reg_write;
  wire [4:0] wb_rd;
  wire [31:0] wb_data;

  immediate_generator imm_gen (
    .instruction(id_instruction),
    .immediate(id_immediate)
  );

  control_unit ctrl (
    .opcode(id_opcode),
    .reg_write(id_reg_write),
    .alu_src(id_alu_src),
    .alu_a_sel(id_alu_a_sel),
    .mem_read(id_mem_read),
    .mem_write(id_mem_write),
    .branch(id_branch),
    .jump(id_jump),
    .jalr(id_jalr),
    .alu_op(id_alu_op),
    .wb_sel(id_wb_sel),
    .valid(id_control_valid)
  );

  alu_control alu_ctrl (
    .opcode(id_opcode),
    .alu_op(id_alu_op),
    .funct3(id_funct3),
    .funct7(id_funct7),
    .alu_sel(id_alu_sel),
    .valid(id_alu_valid)
  );

  register_file rf (
    .clk(clk),
    .rst(rst),
    .reg_write(wb_reg_write),
    .rs1(id_rs1),
    .rs2(id_rs2),
    .rd(wb_rd),
    .write_data(wb_data),
    .read_data1(rf_read1),
    .read_data2(rf_read2)
  );

  // WB-to-ID bypass avoids same-edge read/write hazards.
  assign id_rs1_data =
      (wb_reg_write && wb_rd != 5'd0 && wb_rd == id_rs1)
      ? wb_data : rf_read1;

  assign id_rs2_data =
      (wb_reg_write && wb_rd != 5'd0 && wb_rd == id_rs2)
      ? wb_data : rf_read2;

  // Decode checks beyond the opcode itself.
  wire id_memory_encoding_valid;
  wire id_jalr_encoding_valid;
  wire id_fence_encoding_valid;
  wire id_decode_valid;
  
  wire id_illegal_instruction;

  assign id_illegal_instruction =
      id_valid && !(id_mret && trap_active) &&
      (!id_control_valid ||
       !id_alu_valid ||
       !id_memory_encoding_valid ||
       !id_jalr_encoding_valid ||
       !id_fence_encoding_valid);

  assign id_memory_encoding_valid =
      ((id_opcode == 7'b0000011) ?
        ((id_funct3 == 3'b000) ||
         (id_funct3 == 3'b001) ||
         (id_funct3 == 3'b010) ||
         (id_funct3 == 3'b100) ||
         (id_funct3 == 3'b101)) :
       (id_opcode == 7'b0100011) ?
        ((id_funct3 == 3'b000) ||
         (id_funct3 == 3'b001) ||
         (id_funct3 == 3'b010)) :
        1'b1);

  assign id_jalr_encoding_valid =
      (id_opcode != 7'b1100111) ||
      (id_funct3 == 3'b000);

  assign id_fence_encoding_valid =
      (id_opcode != 7'b0001111) ||
      (id_funct3 == 3'b000);

  assign id_decode_valid =
      id_valid &&
      id_control_valid &&
      id_alu_valid &&
      id_memory_encoding_valid &&
      id_jalr_encoding_valid &&
      id_fence_encoding_valid;

  // =========================================================
  // 4. ID/EX PIPELINE REGISTER
  // =========================================================

  wire ex_valid;
  wire [31:0] ex_pc;
  wire [31:0] ex_rs1_data;
  wire [31:0] ex_rs2_data;
  wire [31:0] ex_immediate;

  wire [4:0] ex_rs1;
  wire [4:0] ex_rs2;
  wire [4:0] ex_rd;
  wire [2:0] ex_funct3;
  wire [3:0] ex_alu_sel;

  wire ex_reg_write;
  wire ex_mem_read;
  wire ex_mem_write;
  wire ex_branch;
  wire ex_jump;
  wire ex_jalr;
  wire ex_alu_src;
  wire ex_alu_a_sel;
  wire [1:0] ex_wb_sel;

  id_ex_reg id_ex_stage (
    .clk(clk),
    .rst(rst),
    .stall(1'b0),
    .flush(hazard_id_ex_flush || branch_id_ex_flush || trap_flush),
    .valid_in(id_decode_valid),
    .pc_in(id_pc),
    .rs1_data_in(id_rs1_data),
    .rs2_data_in(id_rs2_data),
    .immediate_in(id_immediate),

    .rs1_in(id_rs1),
    .rs2_in(id_rs2),
    .rd_in(id_rd),

    .funct3_in(id_funct3),
    .alu_sel_in(id_alu_sel),

    .reg_write_in(id_reg_write && id_decode_valid),
    .mem_read_in(id_mem_read && id_decode_valid),
    .mem_write_in(id_mem_write && id_decode_valid),
    .branch_in(id_branch && id_decode_valid),
    .jump_in(id_jump && id_decode_valid),
    .jalr_in(id_jalr && id_decode_valid),
    .alu_src_in(id_alu_src),
    .alu_a_sel_in(id_alu_a_sel),
    .wb_sel_in(id_wb_sel),

    .valid_out(ex_valid),
    .pc_out(ex_pc),
    .rs1_data_out(ex_rs1_data),
    .rs2_data_out(ex_rs2_data),
    .immediate_out(ex_immediate),

    .rs1_out(ex_rs1),
    .rs2_out(ex_rs2),
    .rd_out(ex_rd),

    .funct3_out(ex_funct3),
    .alu_sel_out(ex_alu_sel),

    .reg_write_out(ex_reg_write),
    .mem_read_out(ex_mem_read),
    .mem_write_out(ex_mem_write),
    .branch_out(ex_branch),
    .jump_out(ex_jump),
    .jalr_out(ex_jalr),
    .alu_src_out(ex_alu_src),
    .alu_a_sel_out(ex_alu_a_sel),
    .wb_sel_out(ex_wb_sel)
  );

  // =========================================================
  // 5. HAZARD DETECTION
  // =========================================================

  hazard_detection_unit hazard_unit (
    .if_id_valid(id_decode_valid),
    .if_id_opcode(id_opcode),
    .if_id_rs1(id_rs1),
    .if_id_rs2(id_rs2),

    .id_ex_valid(ex_valid),
    .id_ex_mem_read(ex_mem_read),
    .id_ex_rd(ex_rd),

    .pc_write(hazard_pc_write),
    .if_id_write(hazard_if_id_write),
    .id_ex_flush(hazard_id_ex_flush),
    .stall(hazard_stall)
  );

  // =========================================================
  // 6. FORWARDING CONTROL
  // =========================================================

  wire [1:0] forward_a;
  wire [1:0] forward_b;

  wire mem_valid;
  wire [4:0] mem_rd;
  wire mem_reg_write;
  wire mem_mem_read;
  wire [1:0] mem_wb_sel;

  wire [31:0] mem_alu_result;
  wire [31:0] mem_pc;
  wire [31:0] mem_pc_plus4;
  wire [31:0] mem_immediate;

  forwarding_unit forward_unit (
    .id_ex_rs1(ex_rs1),
    .id_ex_rs2(ex_rs2),

    .ex_mem_rd(mem_rd),
    .ex_mem_valid(mem_valid),
    .ex_mem_reg_write(mem_reg_write),
    .ex_mem_mem_read(mem_mem_read),

    .mem_wb_rd(wb_rd),
    .mem_wb_valid(wb_valid),
    .mem_wb_reg_write(wb_reg_write),

    .forward_a(forward_a),
    .forward_b(forward_b)
  );

  // Forward the actual available writeback value.
  // EX/MEM load data is intentionally not forwarded here.
  reg [31:0] mem_forward_data;

  always @(*) begin
    case (mem_wb_sel)
      2'b00: mem_forward_data = mem_alu_result;
      2'b10: mem_forward_data = mem_pc_plus4;
      2'b11: mem_forward_data = mem_immediate;
      default: mem_forward_data = 32'd0;
    endcase
  end

  reg [31:0] forwarded_rs1;
  reg [31:0] forwarded_rs2;

  always @(*) begin
    case (forward_a)
      2'b01: forwarded_rs1 = wb_data;
      2'b10: forwarded_rs1 = mem_forward_data;
      default: forwarded_rs1 = ex_rs1_data;
    endcase

    case (forward_b)
      2'b01: forwarded_rs2 = wb_data;
      2'b10: forwarded_rs2 = mem_forward_data;
      default: forwarded_rs2 = ex_rs2_data;
    endcase
  end

  // =========================================================
  // 7. EXECUTE (EX)
  // =========================================================

  wire [31:0] ex_alu_a;
  wire [31:0] ex_alu_b;
  wire [31:0] ex_alu_result;
  wire [31:0] ex_pc_plus4;

  assign ex_alu_a =
      ex_alu_a_sel ? ex_pc : forwarded_rs1;

  assign ex_alu_b =
      ex_alu_src ? ex_immediate : forwarded_rs2;

  assign ex_pc_plus4 = ex_pc + 32'd4;

  alu execute_alu (
    .a(ex_alu_a),
    .b(ex_alu_b),
    .alu_op(ex_alu_sel),
    .result(ex_alu_result)
  );

  // =========================================================
  // 8. BRANCH AND JUMP CONTROL
  // =========================================================

  wire ex_branch_taken;
  wire ex_branch_valid;
  wire ex_target_valid;
  wire ex_control_transfer;
  wire ex_execution_valid;

  branch_control branch_unit (
    .branch_en(ex_valid && ex_branch),
    .funct3(ex_funct3),
    .rs1_data(forwarded_rs1),
    .rs2_data(forwarded_rs2),
    .branch_taken(ex_branch_taken),
    .valid(ex_branch_valid)
  );

  next_pc_logic next_pc_unit (
    .pc(ex_pc),
    .immediate(ex_immediate),
    .rs1_data(forwarded_rs1),
    .branch_taken(ex_branch_taken),
    .jump(ex_valid && ex_jump),
    .jalr(ex_jalr),
    .next_pc(ex_next_pc)
  );

  assign ex_control_transfer =
      ex_valid &&
      ((ex_branch && ex_branch_taken) || ex_jump);

  assign ex_target_valid =
      (ex_next_pc[1:0] == 2'b00);

  assign ex_execution_valid =
      ex_valid &&
      (!ex_branch || ex_branch_valid) &&
      (!ex_control_transfer || ex_target_valid);

  branch_flush_control branch_flush_unit (
    .ex_valid(ex_execution_valid),
    .ex_branch(ex_branch),
    .ex_branch_taken(ex_branch_taken),
    .ex_jump(ex_jump),
    .ex_target_valid(ex_target_valid),

    .pc_redirect(pc_redirect),
    .if_id_flush(branch_if_id_flush),
    .id_ex_flush(branch_id_ex_flush)
  );

  // =========================================================
  // 9. EX/MEM PIPELINE REGISTER
  // =========================================================

  wire [31:0] mem_store_data;
  wire [2:0] mem_funct3;
  wire mem_mem_write;
  
  wire mem_address_misaligned;

  assign mem_address_misaligned =
      ((mem_funct3 == 3'b001) &&
       mem_alu_result[0] != 1'b0) ||
      ((mem_funct3 == 3'b010) &&
       mem_alu_result[1:0] != 2'b00);

ex_mem_trap_reg ex_mem_stage (
    .clk(clk),
    .rst(rst),
    .stall(1'b0),
    .flush(exception_valid && (exception_stage == 2'b11)),

    .valid_in(ex_execution_valid),
    .pc_in(ex_pc),
    .pc_plus4_in(ex_pc_plus4),
    .alu_result_in(ex_alu_result),
    .rs2_data_in(forwarded_rs2),
    .immediate_in(ex_immediate),

    .rd_in(ex_rd),
    .funct3_in(ex_funct3),

    .reg_write_in(ex_reg_write && ex_execution_valid),
    .mem_read_in(ex_mem_read && ex_execution_valid),
    .mem_write_in(ex_mem_write && ex_execution_valid),
    .wb_sel_in(ex_wb_sel),

    .valid_out(mem_valid),
    .pc_out(mem_pc),
    .pc_plus4_out(mem_pc_plus4),
    .alu_result_out(mem_alu_result),
    .rs2_data_out(mem_store_data),
    .immediate_out(mem_immediate),

    .rd_out(mem_rd),
    .funct3_out(mem_funct3),

    .reg_write_out(mem_reg_write),
    .mem_read_out(mem_mem_read),
    .mem_write_out(mem_mem_write),
    .wb_sel_out(mem_wb_sel)
  );

  // =========================================================
  // 10. MEMORY ACCESS (MEM)
  // =========================================================

  wire [31:0] mem_read_data;
  wire mem_access_valid;

  wire active_mem_read;
  wire active_mem_write;
  wire mem_instruction_valid;

  assign active_mem_read =
      mem_valid &&
      mem_mem_read &&
      !mem_address_misaligned &&
      !rst;


  assign active_mem_write =
      mem_valid &&
      mem_mem_write &&
      !mem_address_misaligned &&
      !rst;


  data_memory dmem (
    .clk(clk),
    .mem_read(active_mem_read),
    .mem_write(active_mem_write),
    .funct3(mem_funct3),
    .address(mem_alu_result),
    .write_data(mem_store_data),
    .read_data(mem_read_data),
    .valid(mem_access_valid)
  );

  assign mem_instruction_valid =
      mem_valid && mem_access_valid;

  // =========================================================
  // 11. MEM/WB PIPELINE REGISTER
  // =========================================================

  wire [31:0] wb_pc_plus4;
  wire [31:0] wb_alu_result;
  wire [31:0] wb_memory_data;
  wire [31:0] wb_immediate;
  wire [1:0] wb_sel;
  wire wb_reg_write_raw;

  mem_wb_reg mem_wb_stage (
    .clk(clk),
    .rst(rst),
    .stall(1'b0),
    .flush(exception_valid && (exception_stage == 2'b11)),

    .valid_in(mem_instruction_valid),
    .pc_plus4_in(mem_pc_plus4),
    .alu_result_in(mem_alu_result),
    .memory_data_in(mem_read_data),
    .immediate_in(mem_immediate),

    .rd_in(mem_rd),

    .reg_write_in(mem_reg_write &&
                  mem_instruction_valid),
    .wb_sel_in(mem_wb_sel),

    .valid_out(wb_valid),
    .pc_plus4_out(wb_pc_plus4),
    .alu_result_out(wb_alu_result),
    .memory_data_out(wb_memory_data),
    .immediate_out(wb_immediate),

    .rd_out(wb_rd),

    .reg_write_out(wb_reg_write_raw),
    .wb_sel_out(wb_sel)
  );

  // =========================================================
  // 12. WRITEBACK (WB)
  // =========================================================

  reg [31:0] selected_wb_data;

  always @(*) begin
    case (wb_sel)
      2'b00: selected_wb_data = wb_alu_result;
      2'b01: selected_wb_data = wb_memory_data;
      2'b10: selected_wb_data = wb_pc_plus4;
      2'b11: selected_wb_data = wb_immediate;
      default: selected_wb_data = 32'd0;
    endcase
  end

  assign wb_data = selected_wb_data;

  assign wb_reg_write =
      wb_valid &&
      wb_reg_write_raw &&
      !rst &&
      (wb_rd != 5'd0);

  // =========================================
  // EXCEPTION DETECTION UNIT
  // =========================================

  exception_detection_unit exception_unit (
    .id_valid(id_valid && !hazard_stall && !pc_redirect),
    .id_illegal(id_illegal_instruction),
    .id_pc(id_pc),
    .id_instruction(id_instruction),

    .ex_valid(ex_valid),
    .ex_control_transfer(ex_control_transfer),
    .ex_target_misaligned(!ex_target_valid),
    .ex_pc(ex_pc),
    .ex_target_address(ex_next_pc),

    .mem_valid(mem_valid),
    .mem_read(mem_mem_read),
    .mem_write(mem_mem_write),
    .mem_address_misaligned(mem_address_misaligned),
    .mem_pc(mem_pc),
    .mem_address(mem_alu_result),

    .exception_valid(exception_valid),
    .exception_cause(exception_cause),
    .exception_pc(exception_pc),
    .exception_tval(exception_tval),
    .exception_stage(exception_stage)
  );

  // =========================================
  // TRAP CONTROLLER
  // =========================================

  trap_controller trap_unit (
    .clk(clk),
    .rst(rst),

    .exception_valid(exception_valid),
    .exception_cause(exception_cause),
    .exception_pc(exception_pc),
    .exception_tval(exception_tval),

    .trap_return(trap_return_request),
    .return_address(trap_return_address),

    .mepc(trap_mepc),
    .mcause(trap_mcause),
    .mtval(trap_mtval),
    .trap_active(trap_active),

    .trap_redirect(trap_redirect),
    .trap_target(trap_target),
    .trap_flush(trap_flush)
  );

endmodule