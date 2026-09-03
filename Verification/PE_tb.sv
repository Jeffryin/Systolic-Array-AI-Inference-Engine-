module PE_tb();
	logic clk;
	logic signed [7:0] A_in, B_in;
	logic clear_acc, valid_in, output_enable;
	logic signed [31:0] C_in, C_out;
	logic signed [7:0] A_out, B_out;
	logic valid_out;

	initial clk = 0;
	always #5 clk = ~clk;

	systolic_PE DUT(.clk(clk),
	.A_in(A_in),
	.B_in(B_in),
	.A_out(A_out),
	.B_out(B_out),
	.C_in(C_in),
	.C_out(C_out),
	.clear_acc(clear_acc),
	.valid_in(valid_in),
	.valid_out(valid_out),
	.output_enable(output_enable));

	initial begin
		@(negedge clk);
		//C_in is the "previous" PE's acc_reg value. 
		A_in = 0; B_in = 0; clear_acc = 0; valid_in = 0; output_enable = 0; C_in = 123;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = X",$time, C_out);
		@(negedge clk);
		A_in = 0; B_in = 0; clear_acc = 1; valid_in	= 0; output_enable = 0;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 0", $time, C_out);
		@(negedge clk);
		A_in = 5; B_in = 11; clear_acc = 0; valid_in = 0; output_enable = 0;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 0", $time, C_out);
		@(negedge clk);
		A_in = 5; B_in = 11; clear_acc = 0; valid_in = 1; output_enable= 0;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 55", $time, C_out);
		@(negedge clk);
		A_in = 41; B_in = 8; clear_acc = 0; valid_in = 1; output_enable = 0;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 383", $time, C_out);
		@(negedge clk);
		A_in = 71; B_in = 21; clear_acc = 0; valid_in = 1; output_enable = 0;
		@(posedge clk);
		#1; 
		$display("%0t C_out = %d, expected = 1874", $time, C_out);
		@(negedge clk);
		A_in = 100; B_in = 100; clear_acc =0; valid_in = 0; output_enable = 0;
		@(posedge clk);
		#1;
		//should stay 1874 because the accumulator would not haved added 10000
		$display("%0t C_out = %d, expected = 1874", $time, C_out); 
		@(negedge clk);
		A_in = 0; B_in = 0; clear_acc = 0; valid_in = 0; output_enable = 1; 
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 123", $time, C_out); // C_out = 123, why?
		@(negedge clk);
		A_in = 0; B_in = 0; clear_acc = 1; valid_in = 0; output_enable =0;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 0", $time, C_out);

		//test for priorities within the PE
		@(negedge clk);
		A_in = 5; B_in = 5; clear_acc = 0; valid_in = 1; output_enable = 1;
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 25", $time, C_out);

		@(negedge clk);
		//testing to see whether or not if the PE prioritizes valid_in over output_enable
		A_in = 2; B_in = 2; clear_acc = 0; valid_in = 1; output_enable = 1; 
		@(posedge clk);
		#1;
		$display("%0t C_out = %d, expected = 29",$time, C_out);

		//clear_acc should be the priority over valid_in and output_enable
		@(negedge clk);
		A_in = 3; B_in = 8; clear_acc = 1; valid_in = 1; output_enable = 1;
		@(posedge clk);
		#1; 
		$display("%0t C_out = %d, expected = 0",$time, C_out);

	end
endmodule


/* Test Plan

drive different values of A_in B_in and see the MAC result of it and see what 
the output values are derived from it. 

- A_in and B_in = 0 while all the control signals are low, then 5ns/ps later clear_acc
	-expected: Shouldn't do much since acc_reg at this point should have nothing
- Drive A_in and B_in with values (all control signals low) should do the product of 
A_in * B_in
-Drive valid_in with 1, then should start adding the acc_reg to the product. acc_reg 
should still be zero so it should just be the product
-Drive two more values of A_in and B_in 
	-If it can stay high it should be accumulating
-Drive output_enable to high and valid_in low to start "DRAINING"
	-acc_reg should be equal to C_in
-clear_acc to high 
	- should reset the acc_reg so C_out should be 0. 

Edge cases? 
- min and max values, like 0*0, 0*1, 1*1, or 127*127? 

*/
