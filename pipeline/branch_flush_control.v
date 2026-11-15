module branch_flush_control (
  // Instruction in Execute stage
  input wire ex_valid,
  input wire ex_branch,
  input wire ex_branch_taken,
  input wire ex_jump,

  // Target address validation
  input wire ex_target_valid,

  // Pipeline control outputs
  output reg pc_redirect,
  output reg if_id_flush,
  output reg id_ex_flush
);

  wire valid_control_transfer;

  // A control transfer is required for:
  // 1. A taken conditional branch
  // 2. An unconditional jump (JAL or JALR)

  assign valid_control_transfer =
      ex_valid &&
      ex_target_valid &&
      (
        (ex_branch && ex_branch_taken) ||
        ex_jump
      );

  always @(*) begin

    // Normal sequential execution
    pc_redirect = 1'b0;
    if_id_flush = 1'b0;
    id_ex_flush = 1'b0;

    if (valid_control_transfer) begin

      // Redirect PC to the branch/jump target
      pc_redirect = 1'b1;

      // Remove wrong-path instruction from IF/ID
      if_id_flush = 1'b1;

      // Insert a bubble into ID/EX
      id_ex_flush = 1'b1;

    end

  end

endmodule
