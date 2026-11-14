module AXI_tb();
	parameter DATA_W = 128;
	parameter OUT_W = 512;

	logic clk;
	logic rst_n;
	logic signed [DATA_W-1:0] sa_TDATA;
	logic sa_TVALID;
	logic sa_TREADY;
	logic sa_TLAST;

	logic signed [DATA_W-1:0] sb_TDATA; 
	logic sb_TVALID;
	logic sb_TREADY;
	logic sb_TLAST;

	logic signed [OUT_W-1:0] m_TDATA; 
	logic m_TVALID;
	logic m_TREADY;
	logic m_TLAST;

	logic signed [7:0] sram_A[0:999][0:15][0:15];
	logic signed [7:0] sram_B[0:999][0:15][0:15];
	logic signed [31:0] expected_C[0:999][0:15][0:15];

	int active_tile;
	event tile_verified;

	//AXI instatiation
	systolic_top sys_top(.clk(clk),
		.rst(rst_n),
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
		.m_TLAST(m_TLAST));

	initial clk = 0;
	always #5 clk = ~clk;

	initial begin
		int cycle = 0;
		int col;
		int errors = 0; 
		logic signed [31:0] hw_val, sw_val;
		
		m_TREADY = 1; // Tell the wrapper we are always ready to receive C_out

		forever begin
			@(posedge clk); #1;
			
			if (m_TVALID && m_TREADY) begin
				
				if (cycle == 0) $display("%0t: Receiving Tile %0d Result", $time, active_tile);
				
				// Check all 16 columns simultaneously
				for(col = 0; col < 16; col++) begin
					hw_val = m_TDATA[col*32 +: 32];
					sw_val = expected_C[active_tile][15-cycle][col];
					
					if(hw_val !== sw_val) begin
						$error("%0t Mismatch at Tile %0d, Row %0d, Col %0d: HW=%0d, SW=%0d", 
							   $time, active_tile, cycle, col, hw_val, sw_val);
						errors++; 
					end
				end
				
				cycle++; 
				
				if (cycle == 16) begin
					if (errors == 0)
						// FIXED DISPLAY STATEMENT:
						$display("%0t: Tile %0d PASS! Expected = %d, Actual = %d", $time, active_tile, sw_val, hw_val);
					else
						$display("%0t: Tile %0d FAILED with %0d errors, Expected = %d, Actual = %d", $time, active_tile, errors, sw_val, hw_val);
						
					-> tile_verified;
					cycle = 0; 
					errors = 0;
				end
			end
		end
	end

	initial begin
		rst_n = 1; sa_TVALID = 0; sa_TLAST = 0;
		sb_TVALID = 0; sb_TLAST = 0;
		@(posedge clk); #1;
		rst_n = 0;
		@(posedge clk); #1;
		rst_n = 1;
		for(active_tile = 0; active_tile < 1000; active_tile++) begin
			for(int i = 0; i < 16; i++)begin
				for(int j = 0; j < 16; j++) begin
					sram_A[active_tile][i][j] = $random();
					sram_B[active_tile][i][j] = $random();
				end
			end
			for(int i = 0; i < 16; i++)begin
				for(int j = 0; j < 16; j++)begin
					expected_C[active_tile][i][j] = 0; 
					for(int k = 0; k < 16; k++) begin 
						expected_C[active_tile][i][j] += (sram_A[active_tile][i][k] * sram_B[active_tile][k][j]);
					end
				end
			end

			for(int cycle = 0; cycle < 16; cycle ++) begin
				sa_TVALID = 1;
				sb_TVALID = 1;
				for(int i = 0; i < 16; i++) begin
					sa_TDATA[i*8+:8] = sram_A[active_tile][i][cycle]; 
					sb_TDATA[i*8+:8] = sram_B[active_tile][cycle][i];
				end

				@(posedge clk);
				while(!(sa_TREADY && sb_TREADY)) @(posedge clk);
			end

			sa_TVALID = 0;
			sb_TVALID = 0;
			@(tile_verified);
		end
		$finish;
	end
endmodule 