interface sys_if(input bit clk);
	parameter DATA_W = 128;
	parameter OUT_W = 512;

	logic rst, start, DMA_done;
	logic [DATA_W-1:0] A_in, B_in;
	logic [OUT_W-1:0] C_out;
endinterface