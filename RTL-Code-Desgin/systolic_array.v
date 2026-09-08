module systolic_array();
	parameter DATA_W = 8;
	parameter ACC_W = 32;
	parameter ARRAY_SIZE = 16;

	input clk;
	input clear_acc_global, valid_in_global, output_enable_global;
	input [16*DATA_W-1:0] A_in, B_in;
	output [16*ACC_W-1:0] C_out;

	wire [DATA_W-1:0] A_net[0:ARRAY_SIZE-1][0:ARRAY_SIZE];
	wire [DATA_W-1:0] B_net[0:ARRAY_SIZE][0:ARRAY_SIZE-1];
	wire [ACC_W-1:0] C_net[0:ARRAY_SIZE][0:ARRAY_SIZE-1];

	wire valid_net[0:ARRAY_SIZE-1][0:ARRAY_SIZE];
	wire clear_net[0:ARRAY_SIZE-1][0:ARRAY_SIZE];
	wire drain_net[0:ARRAY_SIZE-1][0:ARRAY_SIZE];

	//input skewers - triangular buffer
	//generate loop to unpack 128 bit inputs and feed them into shift registers
	genvar i;
	
	//unpack A_in into A_net sequentially so = rather than <=
	generate 
		for(i = 0; i < ARRAY_SIZE; i=i+1) begin :skew_gen
			wire [DATA_W-1:0] A_slice = A_in[i*DATA_W +: DATA_W];
			wire [DATA_W-1:0] B_slice = B_in[i*DATA_W +: DATA_W];
			//0 * 8 = 0:7 (8 is the constant width that it should take so it'll take 8 bits)
			if(i==0) begin
				assign A_net[0][0] = A_slice;
				assign B_net[0][0] = B_slice;
				assign clear_net[0][0] = clear_acc_global;
				assign valid_net[0][0] = valid_in_global;
				assign drain_net[0][0] = output_enable_global;
			end
			else begin : delay_block
				//register array and loop integer
				reg [DATA_W-1:0] delay_A[0:i-1];
				reg [DATA_W-1:0] delay_B[0:i-1];
				reg [2:0] delay_ctrl[0:i-1];
				integer n;
				//clocked shift logic
				always @(posedge clk) begin
					delay_A[0] <= A_slice;
					delay_B[0] <= B_slice;
					delay_ctrl[0] <= {valid_in_global, clear_acc_global, output_enable_global};
					for(n=1; n < i; n = n +1)begin
						delay_A[n] <= delay_A[n-1];
						delay_B[n] <= delay_B[n-1];
						delay_ctrl[n] <= delay_ctrl[n-1];
					end
				end
				//continuous assignment to the output net here 
				assign A_net[i][0] = delay_A[i-1];
				assign B_net[0][i] = delay_B[i-1];
				assign clear_net[i][0] = delay_ctrl[i-1][1];
				assign valid_net[i][0] = delay_ctrl[i-1][2];
				assign drain_net[i][0] = delay_ctrl[i-1][0];
		end
	endgenerate

	//instantiate the 16x16 PE array
	generate
		for(j = 0; j < ARRAY_SIZE; j= j+1)begin
			assign C_net[0][j] = 32'd0; //top row has no C_in above it. 
		end
	endgenerate

	genvar j;

	generate 
		for(i = 0; i < ARRAY_SIZE; i = i+1)begin : row_loop
			for(j=0; j < ARRAY_SIZE; j = j+1) begin : col_loop
				systolic_PE pe_ij(.clk (clk),
					.A_in (A_net[i][j]),
					.B_in (B_net[i][j]),
					.A_out (A_net[i][j+1]),
					.B_out (B_net[i+1][j]),
					.C_in (C_net[i][j]),
					.C_out (C_net[i+1][j]),
					.clear_acc (clear_net[i][j]),
					.clear_out (clear_net[i][j+1]),
					.valid_in (valid_net[i][j]),
					.valid_out (valid_net[i][j+1]),
					.output_enable (drain_net[i][j]),
					.output_out (drain_net[i][j+1]));
			end
		end
	endgenerate

	generate 
		for(j = 0; j < ARRAY_SIZE; j = j+1) begin
			assign C_out[j * ACC_W +: ACC_W] = C_net[ARRAY_SIZE][j];
		end
	endgenerate
endmodule