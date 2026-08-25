module FSM();
	localparam IDLE = 4'b0000;
	localparam LOAD_A = 4'b0001;
	localparam LOAD_B = 4'b0010;
	localparam CLEAR_ARRAY = 4'b0011;
	localparam COMPUTE = 4'b0100;
	localparam DRAIN = 4'b0101;
	localparam STORE_C = 4'b0110;
	localparam CHECK_NEXT_TILE = 4'b0111;
	localparam DONE = 4'b1000;

	input clk, reset, start, DMA_done;
	output clear_acc, valid_in, output_enable, DMA_start;
	reg [3:0] current_state, next_state;
	reg [5:0] cycle_counter;

	//sequential State Memory
	always @(posedge clk) begin
		if(reset) current_state <= IDLE;
		else current_state <= next_state;
	end

	//combinational Next state logic
	always @(*) begin
		case(current_state)
			LOAD_A: begin
				DMA_start <= 1; 
				if(DMA_done == 1) next_state <= LOAD_B;
				else next_state <= LOAD_A;
			end
			LOAD_B: begin
				DMA_start <= 1;
				if(DMA_done == 1) next_state <= CLEAR_ARRAY;
				else next_state <= LOAD_B;
			end
			CLEAR_ARRAY: begin
				clear_acc <= 1;
				next_state <= COMPUTE;
			end
			COMPUTE: begin
				valid_in <= 1;
				if(cycle_counter == 45) next_state <= DRAIN;
			end
			DRAIN: begin
				valid_in <= 0;
				if(cycle_counter == 15) next_state <= STORE_C;
			end
			STORE_C: begin
				if(DMA_done) next_state <= CHECK_NEXT_TILE;
				else next_state <= STORE_C;
			end 
			CHECK_NEXT_TILE: next_state <= DONE;
			DONE: next_state <= IDLE;
			default : next_state = IDLE;
		endcase
	end

	//sequential outputs and master counter 	
	always @(posedge clk) begin
		valid_in <= 0;
		clear_acc <= 0;
		DMA_start <= 0;
		if(current_state != next_state) cycle_counter <= 0;
		if(current_state == next_state) cycle_counter = cycle_counter + 1;
	end
endmodule