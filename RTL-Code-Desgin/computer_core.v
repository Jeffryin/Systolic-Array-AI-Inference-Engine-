module computer_core(clk, rst, start, DMA_done, A_in, B_in, C_out, DMA_start);
	parameter DATA_W = 128;
	parameter OUT_W = 512;

	input clk;
	input rst, start, DMA_done;
	input [DATA_W-1:0] A_in, B_in;
	output [OUT_W-1:0] C_out;
	output DMA_start;
	//wires to bridge the FSM and systolic array modules together
	//wires for clear, drain, and valid
	wire valid_internal;
	wire clear_internal;
	wire drain_internal;

	//FSM instantiation
		//outputs will drive the internal routing wires 
	FSM fsm(.clk(clk),
		.reset(rst),
		.start(start),
		.DMA_done(DMA_done),
		.clear_acc(clear_internal),
		.valid_in(valid_internal),
		.output_enable(drain_internal),
		.DMA_start(DMA_start));

	//systolic array instantiation
		//global control signals will be hooked up to the internal routing wires (FSM)
	systolic_array(.clk(clk),
		.clear_acc_global(clear_internal),
		.valid_in_global(valid_internal),
		.output_enable_global(output_enable),
		.A_in(A_in),
		.B_in(B_in),
		.C_out(C_out));
endmodule