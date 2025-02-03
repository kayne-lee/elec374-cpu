module CPU_Datapath(
    input clk, input reset, 
    input [3:0] ALUControl, 
    input [4:0] BusSelect,
    output [31:0] BusOut, 
    output [31:0] ALUResult
);
    wire [31:0] reg_data1, reg_data2, alu_hi, alu_lo;
    wire [31:0] bus_mux_out;

    RegisterFile register_file (
        .clk(clk), .reset(reset),
        .read_sel1(4'b0001), .read_sel2(4'b0010), .write_sel(4'b0011),
        .write_data(ALUResult), .write_enable(1'b1),
        .read_data1(reg_data1), .read_data2(reg_data2)
    );

    ALU alu (
        .A(reg_data1), .B(reg_data2), 
        .ALUControl(ALUControl),
        .ALUResult(ALUResult), .HI(alu_hi), .LO(alu_lo)
    );

    BusMux bus_mux (
        .R0(32'b0), .R1(reg_data1), .R2(reg_data2), 
        .PC(32'b0), .IR(32'b0), .MDR(32'b0), .MAR(32'b0), 
        .HI(alu_hi), .LO(alu_lo), 
        .select(BusSelect), .BusOut(bus_mux_out)
    );

    assign BusOut = bus_mux_out;
endmodule