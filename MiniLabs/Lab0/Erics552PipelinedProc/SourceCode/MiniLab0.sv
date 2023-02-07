module MiniLab0(clk, KEY0, LEDR, SW);

	input wire  		clk;	
	input wire  		KEY0;	// KEY used as RST
	input wire [9:0]	SW;		// Read switch data
	
	output logic [9:0]	LEDR;	// Data written to LED
	
	// Internal nets
	logic   [15:0]	addr;		// Memory address being written
	logic   [15:0]	wdata;		// Data being written
	logic   [15:0]	rdata;		// Read data from MM
	logic   we, re;				// Write enable and read enable from CPU
	logic   rst_n;				// Synchronized rst_n to CPU from rst_synch
	
	// Instantiate reset synchronizer
	rst_synch iRST(.RST_n(KEY0), .rst_n(rst_n), .clk(clk));
	
	// Instantiate CPU
	cpu iCPU(.rst_n(rst_n), .clk(clk), .wdata(wdata), .we(we), .addr(addr), .re(re), .rdata(rdata), .mm_re(mm_re));

    //////////// Address Map ///////////////////////
	//  0xFFFF      |  
	//  ..          |
	//  ..          |   Memory mapped pheripherals
	//  0xC001      |
	//  0xC000      |
	//  ..          |
	//  ..          |
	//  0x2000      |
	//  --------------------------------------------
	//  0x1FFF      |   
	//  ..          |
	//  ..          |   8k implemented SRAM
	//  0x0001      |
	//  0x0000      |
	/////////////////////////////////////////////////
	// Memory mapped space starts from 0x2000 ([15:13] are non-zero)
	assign mm_re = |addr[15:13] & re;
	assign mm_we = |addr[15:13] & we;
	
    always_ff @(negedge clk, negedge rst_n)
		if(!rst_n)
			LEDR <= 10'h000;
		else
			// MM write enable and LED address
			LEDR <= mm_we && (addr == 16'hC001) ? wdata[9:0] : LEDR[9:0];
			
	always_ff @(negedge clk, negedge rst_n)
		if(!rst_n)
			rdata <= 16'hbeef;
		else if (mm_re)
			// SW data is assigned to lower 10-bits of read data
			rdata <= {6'b000000, SW};
		else
			rdata <= 16'hbeef;

endmodule