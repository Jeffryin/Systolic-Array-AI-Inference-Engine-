module systolic_array_tb();
	parameter DATA_W = 8;
	parameter ACC_W = 32;
	parameter ARRAY_SIZE = 16;

	logic clk;
	logic clear_acc_global, valid_in_global, output_enable_global;
	logic [127:0] A_in, B_in;
	logic [511:0] C_out;

	systolic_array dut(.clk (clk),
                     .clear_acc_global (clear_acc_global),
                     .valid_in_global (valid_in_global),
                     .output_enable_global (output_enable_global),
                     .A_in (A_in),
                     .B_in (B_in),
                     .C_out (C_out));

	//16x16 array that accepts 8 bit value
	//what is the point of having two matrices? Is it easier debugging? 
	//If it's for 'matrix multiplication' I don't see how that works since it should 
	//be doing that inside the PEs by the dot product and addition	
	logic [7:0] matrix_A[0:15][0:15];
	logic [7:0] matrix_B[0:15][0:15];

	initial clk = 0;
	always #5 clk = ~clk;

	initial begin
	// 	$fsdbDumpfile("Systolic_array.fsdb");
    // $fsdbDumpvars(0, tb_top);
	    $dumpfile("SA_dump.vcd");
	  	$dumpvars(1);
	end

	initial begin
		clear_acc_global = 0;	
		valid_in_global = 0;
		output_enable_global = 0;
		A_in = '0;
		B_in = '0;

		for(int i = 0; i < 16; i++) begin
			for(int j = 0; j < 16; j++) begin
				matrix_A[i][j] = 127;
				matrix_B[i][j] = 127;
			end
		end

		//10 x 10 padding where it won't utilize all 16x16 PEs 
		// for(int i = 0; i < 16; i++) begin
		// 	for(int j = 0; j < 16; j++) begin
		// 		matrix_A[i][j] = 0;
		// 		matrix_B[i][j] = 0;
		// 	end
		// end
		// for(int i = 0; i < 10; i++) begin
		// 	for(int j = 0; j < 10; j++) begin
		// 		matrix_A[i][j] = 1;
		// 		matrix_B[i][j] = 1;
		// 	end
		// end 

		clear_acc_global = 1; 
		@(posedge clk);
		#1;
		clear_acc_global = 0;
		valid_in_global = 1;
		for (int k = 0; k < 16; k++) begin 
			for(int i = 0; i < 16; i++) begin
				A_in[i*DATA_W +: DATA_W] = matrix_A[i][k];
				$display("%0t A_in = %32h, matrix A (%d, %d) = %d",$time, A_in, i, k, matrix_A[i][k]);
			end

			for(int j = 0; j < 16; j++) begin
				B_in[j*DATA_W +: DATA_W] = matrix_B[k][j];
				$display("%0t B_in = %32h, matrix B (%d, %d) = %d",$time, B_in, k, j, matrix_A[k][j]);
			end
			@(posedge clk);
			#1;
		end

		valid_in_global = 0;

		repeat(46) @(posedge clk);
		for(int i = 0; i < 32; i++) begin
			@(posedge clk); #1;
			$display("%0t Drain cycle has started", $time);
			for(int j = 0; j < 16; j++) begin
				// if(C_out[j*ACC_W +: ACC_W] !== 0) begin
					$display("%0t C_out at column %d = %d",$time, j, $signed(C_out[j*ACC_W +: ACC_W]));
				// end
			end
		end

		output_enable_global = 0;
	end
endmodule 