module RegisterFile(
    input clk, input reset,
    input [3:0] read_sel1, read_sel2, write_sel,
    input [31:0] write_data,
    input write_enable,
    output [31:0] read_data1, read_data2
);
    reg [31:0] registers [15:0];  // 16 registers

    always @(posedge clk or posedge reset) begin
        if (reset)
            for (int i = 0; i < 16; i = i + 1)
                registers[i] <= 32'b0;
        else if (write_enable)
            registers[write_sel] <= write_data;
    end

    assign read_data1 = registers[read_sel1];
    assign read_data2 = registers[read_sel2];
endmodule