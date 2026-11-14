module AXI_Wrapper #(
	parameter DATA_W = 128,
	parameter OUT_W = 512
	)(
	input wire clk,
	input wire rst_n,

	//slave in this case is the chip
	input wire [DATA_W-1:0] sa_TDATA, 
	//the chip is expecting A_in and B_in which are 128 bits wide
	input wire sa_TVALID,
	output wire sa_TREADY,
	input wire sa_TLAST,

	input wire [DATA_W-1:0] sb_TDATA, 
	//the chip is expecting A_in and B_in which are 128 bits wide
	input wire sb_TVALID,
	output wire sb_TREADY,
	input wire sb_TLAST,
	
	//master in this case is the DMA engine
	output wire [OUT_W-1:0] m_TDATA, 
	// the master is expecting C_out which is 512 bits wide
	output wire m_TVALID,
	input wire m_TREADY,
	output wire m_TLAST,

	//with the addition of sram_a,b, and c hard macros need to communicate to it now
	//address width defined by hard macro is 11 bits. 
	output reg [10:0] axi_addr_a, axi_addr_b, axi_addr_c, 
	output wire axi_we_a, axi_we_b, axi_we_c,
	output wire [10:0] core_addr_a, core_addr_b, core_addr_c,
	output wire core_we_c,
	output wire core_is_active,
	input wire [DATA_W-1:0]sram_dout_a,
	input wire [DATA_W-1:0]sram_dout_b,
	output wire [OUT_W]core_c_out
	);

	//internal wires connecting the two AXI interfaces to the compute_core
	wire internal_start;
	wire internal_DMA_done;
	wire internal_DMA_start;
	wire [OUT_W-1:0] C_out_internal;

	wire internal_rst_n = ~rst_n;

	wire both_valid = sa_TVALID & sb_TVALID;

	wire array_ready_to_ingest; 
	wire array_is_draining;
	wire last_drain_cycle;
	wire last_compute_cycle;

	int axi_a_cnt = 0;
	int axi_b_cnt = 0;

	//when sa_TVALID and sa_TREADY are high 
	//writes data to sram_a and its internal axi_addr_a counter. 
	//write enable on the srams are active low 
	assign axi_we_a = (sa_TVALID & sa_TREADY) ? 1'b0 : 1'b1;
	assign axi_we_b = (sb_TREADY & sb_TVALID) ? 1'b0 : 1'b1;
	assign axi_we_c = (m_TREADY & m_TVALID) ? 1'b0 : 1'b1;
	
	//to increment cnt of address it needs to be inside a posedge clk
	always @(posedge clk) begin
		//if reset is on, reset addresses 
		if(~rst_n) begin
			axi_addr_a <= 0;
			axi_addr_b <= 0;
			axi_addr_c <= 0;
		end else begin
			if(~axi_we_a) axi_addr_a <= axi_addr_a + 1; 
			if(~axi_we_b) axi_addr_b <= axi_addr_b + 1;
			if(~axi_we_c) axi_addr_c <= axi_addr_c + 1; 
		end

	end

	assign sa_TREADY = both_valid & array_ready_to_ingest;
	assign sb_TREADY = both_valid & array_ready_to_ingest;
	assign internal_start = both_valid;
	assign internal_DMA_done = 1'b1;

	assign core_is_active = (array_ready_to_ingest | array_is_draining);

	// this was read from AXI
	// wire [127:0] A_in_internal = both_valid ? sa_TDATA : 128'b0;
	// wire [127:0] B_in_internal = both_valid ? sb_TDATA : 128'b0;
	// this is read by sram
	wire [DATA_W-1:0] A_in_internal = sram_dout_a;
	wire [DATA_W-1:0] B_in_internal = sram_dout_b;

	assign core_c_out = C_out_internal;

	//instantiation of the compute core
	compute_core cc(.clk(clk),
		.rst(internal_rst_n),
		.start(internal_start),
		.DMA_done(internal_DMA_done),
		.A_in(A_in_internal),
		.B_in(B_in_internal),
		.C_out(C_out_internal),
		.DMA_start(internal_DMA_start),
		.ready_to_compute(array_ready_to_ingest),
		.array_is_draining(array_is_draining),
		.last_drain_cycle(last_drain_cycle),
		.last_compute_cycle(last_compute_cycle),
		.core_addr_a(core_addr_a),
		.core_addr_b(core_addr_b),
		.core_addr_c(core_addr_c),
		.core_we_c(core_we_c));

	assign m_TDATA = C_out_internal;
	assign m_TVALID = array_is_draining;
	assign m_TLAST = last_drain_cycle;
endmodule