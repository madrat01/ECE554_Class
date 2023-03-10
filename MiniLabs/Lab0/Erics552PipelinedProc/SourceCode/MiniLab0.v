
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module MiniLab0(

	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output reg	     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW
);

//=======================================================
//  REG/WIRE declarations
//=======================================================

	wire   [15:0]	addr;		// Memory address being written
	wire   [15:0]	wdata;		// Data being written
	reg    [15:0]	rdata;		// Read data from MM
	wire   we, re;				// Write enable and read enable from CPU
	wire   rst_n;				// Synchronized rst_n to CPU from rst_synch
	wire   mm_we, mm_re;		// Qualified memory maaped write enable and read enable

//=======================================================
//  Structural coding
//=======================================================

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
	
	always @(negedge CLOCK_50, negedge rst_n)
		if(!rst_n)
			LEDR <= 10'h000;
		else
			// MM write enable and LED address
			LEDR <= mm_we && (addr == 16'hC001) ? wdata[9:0] : LEDR[9:0];
			
	always @(negedge CLOCK_50, negedge rst_n)
		if(!rst_n)
			rdata <= 16'hbeef;
		else if (mm_re)
			// SW data is assigned to lower 10-bits of read data
			rdata <= {6'b000000, SW};
		else
			rdata <= 16'hbeef;

//========================================================
//  Module Instantiations
//========================================================

	// Instantiate reset synchronizer
	rst_synch iRST(.RST_n(KEY[0]), .rst_n(rst_n), .clk(CLOCK_50));
	
	// Instantiate CPU
	cpu iCPU(.rst_n(rst_n), .clk(CLOCK_50), .wdata(wdata), .we(we), .addr(addr), .re(re), .rdata(rdata), .mm_re(mm_re));

endmodule
