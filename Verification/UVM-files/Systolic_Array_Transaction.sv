class Systolic_Array_Transaction extends uvm_sequence_item;
	parameter DATA_W = 128;

	//what is being sent here? A 16x16 data matrix, A_in x B_in. 
	//INT8 so 8 bits of logic x 16 = 128
	//A_in and B_in can be randomized, but does not need to be split up since 
	//the DMA engine should be responsible for this. Do I need to make a DMA engine
	//reset, start and DMA_done are also being sent to drive the DUT. 
	//all inputs can be randomized

	rand logic [DATA_W-1:0] A_in;
	rand logic [DATA_W-1:0] B_in;
	rand logic rst, start, DMA_done;

	constraint input_data {
		A_in inside {[-128,127]};
		B_in inside {[-128,127]};
	}

	`uvm_object_utils_begin(Systolic_Array_Transaction)
		`uvm_field_int(A_in, UVM_ALL_ON)
		`uvm_field_int(B_in, UVM_ALL_ON)
		`uvm_field_int(rst, UVM_ALL_ON)
		`uvm_field_int(start, UVM_ALL_ON)
		`uvm_field_int(DMA_done, UVM_ALL_ON)
	`uvm_object_utils begin_end

	