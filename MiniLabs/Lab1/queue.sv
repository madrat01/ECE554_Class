module queue(clk, rst_n, in_data, re, we, out_data, free_entries, filled_entries, empty, full);
	input clk, rst_n;
	input [7:0] in_data;
	input re, we;
	
	output [7:0] out_data;
	output [3:0] free_entries, filled_entries;
	output empty, full;
	
	logic [7:0] buffer [7:0];
	logic [3:0] new_ptr, old_ptr;

	// continuous assign for out_data from wherever old_ptr is pointing
	assign out_data = buffer[old_ptr[2:0]];
	assign empty = old_ptr == new_ptr;
	assign full = new_ptr[2:0] == old_ptr[2:0] && old_ptr[3] != new_ptr[3];
	assign free_entries = new_ptr[3] == old_ptr[3] ? 4'h8 - (new_ptr[2:0] - old_ptr[2:0]) : old_ptr[2:0] - new_ptr[2:0];
	assign filled_entries = 4'h8 - free_entries;

	// logic for maintaining old_ptr
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n) // reset
			old_ptr <= 4'b000;
		else if (re & !empty) // increment old_ptr only if there is data to be read and read is enabled
			old_ptr <= old_ptr + 4'b001;
		
    // logic for maintaining new_ptr		
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			new_ptr <= 4'b0000;
		else if (we && ~full) // increment only if write is enable and queue not full
			new_ptr <= new_ptr + 4'b0001;

	always_ff @(posedge clk)
		if (we && ~full)
			buffer[new_ptr[2:0]] <= in_data;
	
endmodule