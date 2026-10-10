module FSM_tb();
	logic clk;
	logic reset, start, DMA_done;
	logic clear_acc, valid_in, output_enable, DMA_start;

	initial clk = 0;
	always #5 clk = ~clk;

	FSM fsm(.clk(clk),
		.reset(reset),
		.start(start),
		.DMA_done(DMA_done),
		.clear_acc(clear_acc),
		.valid_in(valid_in),
		.output_enable(output_enable),
		.DMA_start(DMA_start));

	initial begin
		start = 0;
		DMA_done =0;
		reset = 1;

		@(posedge clk);
		#1; 
		reset = 0;

		//trigger FSM
		start = 1;
		@(posedge clk);
		start = 0;

		$display("%0t FSM starting", $time);

		//LOAD_A
		$display("%0t waiting for LOAD_A to start",$time);
		wait(DMA_start == 1);
		$display("%0t DMA started", $time);
		repeat(5) @(posedge clk);
		DMA_done = 1;
		@(posedge clk); #1; 
		DMA_done = 0;
		$display("%0t LOAD_A completed", $time);

		//LOAD_B
		$display("%0t waiting for LOAD_B to start", $time);
		wait(DMA_start == 1);
		$display("%0t DMA started", $time);
		repeat(5) @(posedge clk);
		DMA_done = 1; 
		@(posedge clk); #1;
		DMA_done = 0;
		$display("%0t LOAD_B completed",$time);

		//clear_array
		$display("%0t waiting to clear array", $time);
		wait(clear_acc == 1);
		$display("%0t clear array completed", $time);

		//CHECK COMPUTE AND DRAIN TIMERS
		$display("%0t waiting for valid_in to start compute",$time);
		wait(valid_in == 1);
		$display("%0t compute started", $time);
		repeat(45) @(posedge clk);

		$display("%0t waiting for output_enable to start drain", $time);
		wait(output_enable == 1);
		$display("%0t Drain started", $time);
		repeat(15) @(posedge clk);

		//STORE_C
		DMA_done =1;
		@(posedge clk); #1;
		DMA_done = 0;

		//RETURNS TO IDLE
		repeat(5) @(posedge clk);
		$finish;
	end
endmodule