`timescale 1ns/10ps

module control_unit_tb; 	
reg reset;
reg stop;
reg [31:0] inport_in;
wire [31:0] outport_data;
reg clk;
reg clr;

// instantiate DUT
datapath DUT(
	.clk(clk),
	.reset(reset),
    .stop(stop),
    .inport_in(inport_in),
    .outport_data(outport_data)
);

// initialize clock
initial begin
	clk = 0;
	forever #10 clk = ~ clk;
end

initial begin
	reset = 1;
	#20 reset = 0;
end

endmodule
