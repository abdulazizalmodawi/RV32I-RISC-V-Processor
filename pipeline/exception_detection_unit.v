
module exception_detection_unit (
  // =========================================
  // ID STAGE: Illegal instruction
  // =========================================
  input wire id_valid,
  input wire id_illegal,
  input wire [31:0] id_pc,
  input wire [31:0] id_instruction,

  // =========================================
  // EX STAGE: Instruction address misaligned
  // =========================================
  input wire ex_valid,
  input wire ex_control_transfer,
  input wire ex_target_misaligned,
  input wire [31:0] ex_pc,
  input wire [31:0] ex_target_address,

  // =========================================
  // MEM STAGE: Data address misaligned
  // =========================================
  input wire mem_valid,
  input wire mem_read,
  input wire mem_write,
  input wire mem_address_misaligned,
  input wire [31:0] mem_pc,
  input wire [31:0] mem_address,

  // =========================================
  // EXCEPTION OUTPUTS
  // =========================================
  output reg exception_valid,
  output reg [31:0] exception_cause,
  output reg [31:0] exception_pc,
  output reg [31:0] exception_tval,
  output reg [1:0] exception_stage
);

  // RISC-V synchronous exception codes
  localparam [31:0] CAUSE_INST_MISALIGNED = 32'd0;
  localparam [31:0] CAUSE_ILLEGAL_INST    = 32'd2;
  localparam [31:0] CAUSE_LOAD_MISALIGNED = 32'd4;
  localparam [31:0] CAUSE_STORE_MISALIGNED = 32'd6;

  // Stage identification
  localparam [1:0] STAGE_NONE = 2'b00;
  localparam [1:0] STAGE_ID   = 2'b01;
  localparam [1:0] STAGE_EX   = 2'b10;
  localparam [1:0] STAGE_MEM  = 2'b11;

  wire mem_load_exception;
  wire mem_store_exception;
  wire ex_instruction_exception;
  wire id_illegal_exception;

  assign mem_load_exception =
      mem_valid &&
      mem_read &&
      !mem_write &&
      mem_address_misaligned;

  assign mem_store_exception =
      mem_valid &&
      mem_write &&
      !mem_read &&
      mem_address_misaligned;

  assign ex_instruction_exception =
      ex_valid &&
      ex_control_transfer &&
      ex_target_misaligned;

  assign id_illegal_exception =
      id_valid &&
      id_illegal;

  // =========================================
  // EXCEPTION PRIORITY
  //
  // MEM > EX > ID
  //
  // Older instructions have higher priority.
  // =========================================

  always @(*) begin

    // Safe defaults
    exception_valid = 1'b0;
    exception_cause = 32'd0;
    exception_pc = 32'd0;
    exception_tval = 32'd0;
    exception_stage = STAGE_NONE;

    // ---------------------------------------
    // MEM: Load address misaligned
    // ---------------------------------------
    if (mem_load_exception) begin

      exception_valid = 1'b1;
      exception_cause = CAUSE_LOAD_MISALIGNED;
      exception_pc = mem_pc;
      exception_tval = mem_address;
      exception_stage = STAGE_MEM;

    end

    // ---------------------------------------
    // MEM: Store address misaligned
    // ---------------------------------------
    else if (mem_store_exception) begin

      exception_valid = 1'b1;
      exception_cause = CAUSE_STORE_MISALIGNED;
      exception_pc = mem_pc;
      exception_tval = mem_address;
      exception_stage = STAGE_MEM;

    end

    // ---------------------------------------
    // EX: Instruction target misaligned
    // ---------------------------------------
    else if (ex_instruction_exception) begin

      exception_valid = 1'b1;
      exception_cause = CAUSE_INST_MISALIGNED;
      exception_pc = ex_pc;
      exception_tval = ex_target_address;
      exception_stage = STAGE_EX;

    end

    // ---------------------------------------
    // ID: Illegal instruction
    // ---------------------------------------
    else if (id_illegal_exception) begin

      exception_valid = 1'b1;
      exception_cause = CAUSE_ILLEGAL_INST;
      exception_pc = id_pc;
      exception_tval = id_instruction;
      exception_stage = STAGE_ID;

    end

  end

endmodule
