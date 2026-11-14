module FSM(clk, reset, start, DMA_done, clear_acc, valid_in, output_enable, DMA_start, ready_to_compute, array_is_draining, last_drain_cycle, last_compute_cycle,core_addr_a, core_addr_b, core_addr_c, core_we_c);
	localparam IDLE = 4'b0000;
	localparam CLEAR_ARRAY = 4'b0001;//was 4'b0011;
	localparam COMPUTE = 4'b0010;//was 4'b0100;
	localparam DRAIN = 4'b0011;//was 4'b0101;
	localparam STORE_C = 4'b0100;//was 4'b0110;
	localparam CHECK_NEXT_TILE = 4'b0101;//was 4'b0111;
	localparam DONE = 4'b0110;//was 4'b1000;

	input clk, reset, start, DMA_done;
	output reg clear_acc, valid_in, output_enable, DMA_start;
	reg [3:0] current_state, next_state;
	reg [5:0] cycle_counter;
	output wire ready_to_compute;
	output wire array_is_draining;
	output wire last_drain_cycle;
	output wire last_compute_cycle;
	//sram addresses
	output reg [10:0] core_addr_a, core_addr_b, core_addr_c;
	output reg core_we_c;
	//compute core
	assign ready_to_compute = (current_state == COMPUTE);
	assign array_is_draining = output_enable;
	assign last_drain_cycle = (current_state == DRAIN && cycle_counter == 15); 
	assign last_compute_cycle = (current_state == COMPUTE && cycle_counter ==45);

	//sequential State Memory
	always @(posedge clk) begin
		if(reset) current_state <= IDLE;
		else current_state <= next_state;
	end

	//combinational Next state logic
	always @(*) begin
		case(current_state)
			IDLE: begin
				if(start) next_state = CLEAR_ARRAY;
				else next_state = IDLE;
			end
			//deleted LOAD_A + LOAD_B
			CLEAR_ARRAY: begin
				next_state = COMPUTE;
			end
			COMPUTE: begin
				if(cycle_counter == 45)begin
					next_state = DRAIN;
				end
				else next_state = COMPUTE;
			end
			DRAIN: begin
				if(cycle_counter == 15) next_state = STORE_C;
				else next_state = DRAIN;
			end
			STORE_C: begin
				if(DMA_done) next_state = CHECK_NEXT_TILE;
				else next_state = STORE_C;
			end 
			CHECK_NEXT_TILE: next_state = DONE;
			DONE: next_state = IDLE;
			default : next_state = IDLE;
		endcase
	end

	//add core_address indexing here
	always @(posedge clk) begin
		if(reset) begin
			cycle_counter <= 0;
			core_addr_a <= 0;
			core_addr_b <= 0;
		end else begin
			if(current_state != next_state) cycle_counter <= 0;
			else cycle_counter <= cycle_counter + 1;
			if(current_state == COMPUTE && cycle_counter < 16) begin
				core_addr_a <= core_addr_a + 1;
				core_addr_b <= core_addr_b + 1;
			end
		end
	end

	// 4. Combinational Outputs (MUST be immediate, using '=' not '<=') 	
	always @(*) begin
		// Default values to prevent latches
		valid_in = 0;
		clear_acc = 0;
		output_enable = 0;
		DMA_start = 0;
		
		if(current_state == STORE_C && cycle_counter == 0) DMA_start = 1;
		if(current_state == CLEAR_ARRAY) clear_acc = 1;
		if(current_state == COMPUTE) valid_in = 1;
		if(current_state == DRAIN) output_enable = 1;
	end
endmodule
