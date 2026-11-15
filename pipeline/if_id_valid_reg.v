module if_id_valid_reg (
  input wire clk,
  input wire rst,
  input wire stall,
  input wire flush,

  // Instruction validity from IF stage
  input wire valid_in,

  // Registered validity for ID stage
  output reg valid_out
);

  // Priority: Reset > Flush > Stall > Update
  always @(posedge clk) begin

    if (rst) begin
      valid_out <= 1'b0;
    end

    else if (flush) begin
      // Invalidate wrong-path instructions
      valid_out <= 1'b0;
    end

    else if (!stall) begin
      // Capture validity of fetched instruction
      valid_out <= valid_in;
    end

    // Stall: retain previous validity

  end

endmodule
