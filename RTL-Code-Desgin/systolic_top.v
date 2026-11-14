//should modify the top level to not copy + paste the modules but rather instantiate
//needs the `include filename.v 

`include "compute_core.v"
`include "systolic_PE.v"
`include "FSM.v"
`include "AXI_Wrapper.v"
`include "systolic_array.v"
`include "sram_128b_2048_1rw_freepdk45.v"
`include "sram_512b_2048_1rw_freepdk45.v"

module systolic_top #(
	parameter DATA_W = 128,
	parameter OUT_W = 512
	)(
	input clk,
	input rst,
	//slave A
	input wire [DATA_W-1:0] sa_TDATA, 
	input wire sa_TVALID,
	output wire sa_TREADY,
	input wire sa_TLAST,
	//slave B
	input wire [DATA_W-1:0] sb_TDATA, 
	input wire sb_TVALID,
	output wire sb_TREADY,
	input wire sb_TLAST,
	//master
	output wire [OUT_W-1:0] m_TDATA, 
	output wire m_TVALID,
	input wire m_TREADY,
	output wire m_TLAST
	);
	wire [DATA_W-1:0] dout_a, dout_b;
	wire [OUT_W-1:0] core_answers;
	wire [10:0] axi_addr_a, axi_addr_b, axi_addr_c;
	wire axi_we_a, axi_we_b, axi_we_c;
	//requires core addr and we
	wire [10:0] core_addr_a, core_addr_b, core_addr_c;
	wire core_we_c;
	wire core_active;

	wire [10:0] addr_a = core_active ? core_addr_a : axi_addr_a;
	wire [10:0] addr_b = core_active ? core_addr_b : axi_addr_b;

	wire we_a = core_active ? 1'b1 : axi_we_a;
	wire we_b = core_active ? 1'b1 : axi_we_b;

	wire [10:0] addr_c = core_active ? core_addr_c : axi_addr_c;
	wire we_c = core_active ? core_we_c : 1'b1;
	

	wire sa = sa_TREADY & sa_TVALID;
	wire sb = sb_TREADY & sb_TVALID;
	wire sc = m_TREADY & m_TVALID;
	wire cs_a = 1'b0;
	wire cs_b = 1'b0;
	wire cs_c = 1'b0;

	//instantiation of sram_a and b
	sram_128b_2048_1rw_freepdk45 sram_a (
		.clk0(clk),
		.csb0(cs_a),
		.web0(we_a),
		.addr0(addr_a),
		.din0(sa_TDATA),
		.dout0(dout_a));

	sram_128b_2048_1rw_freepdk45 sram_b (
		.clk0(clk),
		.csb0(cs_b),
		.web0(we_b),
		.addr0(addr_b),
		.din0(sb_TDATA),
		.dout0(dout_b));

	//instantiation of sram_c
	sram_512b_2048_1rw_freepdk45 sram_c (
		.clk0(clk),
		.csb0(cs_c),
		.web0(we_c),
		.addr0(addr_c),
		.din0(core_answers),
		.dout0(m_TDATA));

	//instantiation of AXI_Wrapper.v
	//AXI instantiates the compute core and all other dependent modules like the 
	//systolic_array and PE(processing element)
	AXI_Wrapper AXI(
		.clk(clk),
		.rst_n(rst),
		.sa_TDATA(sa_TDATA), 
		.sa_TVALID(sa_TVALID),
		.sa_TREADY(sa_TREADY),
		.sa_TLAST(sa_TLAST),
		.sb_TDATA(sb_TDATA), 
		.sb_TVALID(sb_TVALID),
		.sb_TREADY(sb_TREADY),
		.sb_TLAST(sb_TLAST),
		.m_TDATA(m_TDATA), 
		.m_TVALID(m_TVALID),
		.m_TREADY(m_TREADY),
		.m_TLAST(m_TLAST),
		.axi_addr_a(axi_addr_a),
		.axi_addr_b(axi_addr_b),
		.axi_addr_c(axi_addr_c),
		.axi_we_a(axi_we_a),
		.axi_we_b(axi_we_b),
		.axi_we_c(axi_we_c),
		.core_addr_a(core_addr_a),
		.core_addr_b(core_addr_b),
		.core_addr_c(core_addr_c),
		.core_we_c(core_we_c),
		.core_is_active(core_active),
		.sram_dout_a(dout_a),
		.sram_dout_b(dout_b),
		.core_c_out(core_answers));
endmodule