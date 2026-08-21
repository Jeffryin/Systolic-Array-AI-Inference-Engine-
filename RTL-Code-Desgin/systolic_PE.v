module systolic_PE(clk, A_in, B_in, A_out, B_out, C_in, C_out, clear_acc, valid_in, valid_out, output_enable);
	parameter DATA_W = 8;
	parameter ACC_W = 32;

	input clk;
	input signed [DATA_W -1:0] A_in, B_in;
	input clear_acc, valid_in,output_enable;
	input signed [ACC_W-1:0] C_in;
	output signed [DATA_W -1:0] A_out, B_out;
	output signed [ACC_W-1:0] C_out;
	output valid_out;
	reg signed [DATA_W-1:0] A_reg, B_reg;
	reg valid_reg;
	reg signed [ACC_W-1:0] acc_reg;
	wire signed [(DATA_W*2)-1:0] product;

	assign product = A_in * B_in;

	always @ (posedge clk) begin
		A_reg <= A_in;
		B_reg <= B_in;
		valid_reg <= valid_in;
		if(clear_acc == 1) acc_reg <= 0;
		else if (valid_in == 1) begin
			acc_reg <= acc_reg + product;
		end
		else if (output_enable == 1) acc_reg <= C_in; //draining of the PEs
	end

	assign A_out = A_reg;
	assign B_out = B_reg;
	assign valid_out = valid_reg;
	assign C_out = acc_reg;
endmodule