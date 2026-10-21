module cc_tb();
	parameter DATA_W = 128;
	parameter OUT_W = 512;

	localparam IDLE = 4'b0000;
	localparam LOAD_A = 4'b0001;
	localparam LOAD_B = 4'b0010;
	localparam CLEAR_ARRAY = 4'b0011;
	localparam COMPUTE = 4'b0100;
	localparam DRAIN = 4'b0101;
	localparam STORE_C = 4'b0110;
	localparam CHECK_NEXT_TILE = 4'b0111;
	localparam DONE = 4'b1000;

	//4 tiles of 16x16 data 
	logic[7:0] sram_A [0:3][0:15][0:15];
	logic[7:0] sram_B [0:3][0:15][0:15];
	logic[31:0] sram_C [];

	//port declarations + DUT instantiation
	logic clk;
	logic rst, start, DMA_done;
	logic [DATA_W-1:0] A_in, B_in;
	logic [OUT_W-1:0] C_out;
	logic DMA_start;
	int active_tile;

	compute_core cc(.clk(clk),
		.rst(rst),
		.start(start),
		.DMA_done(DMA_done),
		.A_in(A_in),
		.B_in(B_in),
		.C_out(C_out),
		.DMA_start(DMA_start));

	initial clk = 0;
	always #5 clk = ~clk;

	//task to simulate the DMA
	//wait for FSM to request DMA 
	task automatic DMA_Service();
		wait(DMA_start == 1);
		repeat(4) @(posedge clk); #1;
		DMA_done = 1;
		@(posedge clk);
		DMA_done = 0;
	endtask

	//input streamer 
	initial begin
		forever begin
			wait(cc.fsm.valid_in == 1);
			for(int cycle = 0; cycle < 16; cycle++) begin // Time loop
				for(int i = 0; i < 16; i++) begin // Space loop
					// i indexes the wire slice so all 128 bits pack instantly
					A_in[i*8+:8] = sram_A[active_tile][i][cycle]; 
					B_in[i*8+:8] = sram_B[active_tile][cycle][i]; 
				end
				@(posedge clk); #1;
			end

			A_in = '0;
			B_in = '0;

			wait(cc.fsm.valid_in == 0);
		end
	end

	//output catcher
	initial begin
		forever begin
			wait(cc.fsm.output_enable == 1);
			for(int i = 0; i < 32; i++) begin
				@(posedge clk); #1;
				for(int j = 0; j < 16; j++)begin
					//Since C_out should be a singular value, at the end, we need to copy
					//the 16 values from the last row of the array to 
					$display("%0t C_out at col %d = %d", $time , j, $signed(C_out[j*32 +: 32]));
					//concatenate the values together to create the 512 bit value
				end
			end
			wait(cc.fsm.output_enable == 0);		
		end
	end

	//test sequence
	initial begin 
		//inputs set to 0 so no unknown states
		rst = 0; start = 0; DMA_done = 0;
		A_in = '0; B_in = '0; active_tile = 0;
		//test cases into sram will be random
		for(int num = 0; num < 4; num++) begin
			for(int i = 0; i < 16; i++) begin
				for(int j = 0; j< 16; j++) begin
					sram_A[num][i][j] = $random();
					sram_B[num][i][j] = $random();
				end
			end
		end

		rst = 1; @(posedge clk); #1;
		rst = 0;

		$display("%0t Tile 1", $time);
		start = 1; @(posedge clk); #1; start = 0; 

		DMA_Service();
		DMA_Service();

		$display("%0t waiting for current state to be STORE_C",$time);
		wait(cc.fsm.current_state == STORE_C);
		$display("%0t current state is STORE_C",$time);
		DMA_Service();
		$display("%0t waiting for current_state to be CHECK_NEXT_TILE", $time);
		wait(cc.fsm.current_state == CHECK_NEXT_TILE);
		$display("%0t current state is CHECK_NEXT_TILE",$time);
		$display("%0t waiting for current state to be done",$time);
		wait(cc.fsm.current_state == DONE);
		@(posedge clk); #1;
		$display("%0t current state is DONE",$time);

		$display("%0t Tile 1 done", $time);
		wait(cc.fsm.current_state == IDLE);
		
		$display("%0t Tile 2", $time);
		start = 1; @(posedge clk); #1; start = 0; 

		DMA_Service();
		DMA_Service();

		$display("%0t waiting for current state to be STORE_C",$time);
		wait(cc.fsm.current_state == STORE_C);
		$display("%0t current state is STORE_C",$time);
		DMA_Service();
		$display("%0t waiting for current_state to be CHECK_NEXT_TILE", $time);
		wait(cc.fsm.current_state == CHECK_NEXT_TILE);
		$display("%0t current state is CHECK_NEXT_TILE",$time);
		$display("%0t waiting for current state to be done",$time);
		wait(cc.fsm.current_state == DONE);
		@(posedge clk); #1;
		$display("%0t current state is DONE",$time);

		$display("%0t Tile 2 done", $time);
		wait(cc.fsm.current_state == IDLE);

		$display("%0t Tile 3", $time);
		start = 1; @(posedge clk); #1; start = 0; 

		DMA_Service();
		DMA_Service();

		$display("%0t waiting for current state to be STORE_C",$time);
		wait(cc.fsm.current_state == STORE_C);
		$display("%0t current state is STORE_C",$time);
		DMA_Service();
		$display("%0t waiting for current_state to be CHECK_NEXT_TILE", $time);
		wait(cc.fsm.current_state == CHECK_NEXT_TILE);
		$display("%0t current state is CHECK_NEXT_TILE",$time);
		$display("%0t waiting for current state to be done",$time);
		wait(cc.fsm.current_state == DONE);
		@(posedge clk); #1;
		$display("%0t current state is DONE",$time);

		$display("%0t Tile 3 done", $time);
		wait(cc.fsm.current_state == IDLE);

		$display("%0t Tile 4", $time);
		start = 1; @(posedge clk); #1; start = 0; 

		DMA_Service();
		DMA_Service();

		$display("%0t waiting for current state to be STORE_C",$time);
		wait(cc.fsm.current_state == STORE_C);
		$display("%0t current state is STORE_C",$time);
		DMA_Service();
		$display("%0t waiting for current_state to be CHECK_NEXT_TILE", $time);
		wait(cc.fsm.current_state == CHECK_NEXT_TILE);
		$display("%0t current state is CHECK_NEXT_TILE",$time);
		$display("%0t waiting for current state to be done",$time);
		wait(cc.fsm.current_state == DONE);
		@(posedge clk); #1;
		$display("%0t current state is DONE",$time);

		$display("%0t Tile 4 done", $time);
		wait(cc.fsm.current_state == IDLE);
		$display("%0t Tile 5",$time);
		active_tile++;
		start = 1; @(posedge clk); #1; start = 0;
		$finish;
	end
endmodule