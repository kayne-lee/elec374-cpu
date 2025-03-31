module ram_512x32 (
    input wire clk,
    input wire [8:0] addr,
    input wire [31:0] data_in,
    input wire write_enable,
    output reg [31:0] data_out
);

    // RAM storage
    reg [31:0] memory [0:511]; // 512 x 32-bit memory

    initial begin 
          $readmemh("C:/Users/21mw67/Downloads/phase1/initram.mem", memory);

    end

    // Write operation
    always @(posedge clk) begin
        if (write_enable) begin
            memory[addr] <= data_in;  // Write data into memory at addr
        end
    end

    // Read operation
    always @(posedge clk) begin
        data_out <= memory[addr]; // Read data from memory at addr
    end

endmodule