module instruction_memory (
  input wire [31:0] pc,
  output reg [31:0] instruction,
  output reg valid
);

  parameter MEM_WORDS = 256;

  reg [31:0] memory [0:MEM_WORDS-1];
  integer i;

  // Initialize memory with NOP instructions.
  // Testbench can preload instructions for simulation.
  initial begin
    for (i = 0; i < MEM_WORDS; i = i + 1)
      memory[i] = 32'h00000013;
  end

  // Asynchronous instruction fetch.
  // RV32I instructions must be 4-byte aligned.
  always @(*) begin
    instruction = 32'h00000013;
    valid = 1'b0;

    if ((pc[1:0] == 2'b00) &&
        (pc < MEM_WORDS * 4)) begin
      instruction = memory[pc >> 2];
      valid = 1'b1;
    end
  end

endmodule
