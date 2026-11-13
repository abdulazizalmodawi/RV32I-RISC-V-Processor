module data_memory (
  input wire clk,
  input wire mem_read,
  input wire mem_write,
  input wire [2:0] funct3,
  input wire [31:0] address,
  input wire [31:0] write_data,
  output reg [31:0] read_data,
  output reg valid
);

  parameter MEM_BYTES = 1024;

  reg [7:0] memory [0:MEM_BYTES-1];
  reg [2:0] access_size;
  reg [31:0] raw_data;
  integer i;

  // Simulation initialization
  initial begin
    for (i = 0; i < MEM_BYTES; i = i + 1)
      memory[i] = 8'd0;
  end

  // Access validation and asynchronous read
  always @(*) begin
    read_data = 32'd0;
    raw_data = 32'd0;
    valid = 1'b1;
    access_size = 3'd1;

    if (mem_read && mem_write) begin
      valid = 1'b0;
    end else if (mem_read) begin
      case (funct3)
        3'b000, 3'b100: access_size = 3'd1;
        3'b001, 3'b101: access_size = 3'd2;
        3'b010:         access_size = 3'd4;
        default:        valid = 1'b0;
      endcase
    end else if (mem_write) begin
      case (funct3)
        3'b000: access_size = 3'd1;
        3'b001: access_size = 3'd2;
        3'b010: access_size = 3'd4;
        default: valid = 1'b0;
      endcase
    end

    if (mem_read || mem_write) begin
      // Check memory bounds
      if (address > MEM_BYTES - access_size)
        valid = 1'b0;

      // Check natural alignment
      if ((access_size == 3'd2 && address[0] != 1'b0) ||
          (access_size == 3'd4 && address[1:0] != 2'b00))
        valid = 1'b0;
    end

    if (mem_read && valid) begin
      case (access_size)
        3'd1:
          raw_data = {24'd0, memory[address]};

        3'd2:
          raw_data = {16'd0,
                      memory[address + 32'd1],
                      memory[address]};

        3'd4:
          raw_data = {
            memory[address + 32'd3],
            memory[address + 32'd2],
            memory[address + 32'd1],
            memory[address]
          };

        default: raw_data = 32'd0;
      endcase

      case (funct3)
        3'b000:
          read_data = {{24{raw_data[7]}}, raw_data[7:0]};

        3'b001:
          read_data = {{16{raw_data[15]}}, raw_data[15:0]};

        3'b010:
          read_data = raw_data;

        3'b100:
          read_data = {24'd0, raw_data[7:0]};

        3'b101:
          read_data = {16'd0, raw_data[15:0]};

        default:
          read_data = 32'd0;
      endcase
    end
  end

  // Synchronous memory write (little-endian)
  always @(posedge clk) begin
    if (mem_write && valid) begin
      case (funct3)
        // SB
        3'b000:
          memory[address] <= write_data[7:0];

        // SH
        3'b001: begin
          memory[address] <= write_data[7:0];
          memory[address + 32'd1] <= write_data[15:8];
        end

        // SW
        3'b010: begin
          memory[address] <= write_data[7:0];
          memory[address + 32'd1] <= write_data[15:8];
          memory[address + 32'd2] <= write_data[23:16];
          memory[address + 32'd3] <= write_data[31:24];
        end
      endcase
    end
  end

endmodule
