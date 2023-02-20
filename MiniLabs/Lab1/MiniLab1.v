
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module MiniLab1(

	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		clk,

	//////////// RST_N //////////
	input 		        		RST_n,

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
	wire   [15:0]	rdata;		// Read data from MM
	wire   [15:0]	SW_rdata;   // Read data from SW
	wire            we, re;				// Write enable and read enable from CPU
	wire            rst_n;				// Synchronized rst_n to CPU from rst_synch
	wire            mm_we, mm_re;		// Qualified memory maaped write enable and read enable
	wire   [15:0]	SPART_rdata;   // Read data from SPART
    wire   [7:0]    databus;    // An 8-bit, 3-state bidirectional bus used to transfer data and control information between the Processor and the SPART.
    reg    [1:0]    ioaddr;     // A 2-bit address bus used to select the particular register that interacts with the databus during an I/O operation
    wire            iorw_n;     // Determines the direction of data transfer between the Processor and SPART. For a read (iorw_n=1), data is transferred from the SPART to the Processor and for a write (iorw_n=0), data is transferred from the processor to the SPART
    wire            iocs_n;     // Active low chip select. Writes or reads to registers have no effect unless active
    wire            rx_q_empty; // If 1 then no receive data present to read
    wire            tx_q_full;  // If 1 then transmit queue is full and cannot accept anymore bytes
	wire			TX, RX; 	// UART TX and RX lines
	wire			spart_read_reg_dec;		// Address decode matches a SPART register to read
	wire			spart_write_reg_dec;	// Address decode matches a SPART register to write

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

//===============================
//  LEDR Read and Write
//===============================

	always @(negedge clk, negedge rst_n)
		if(!rst_n)
			LEDR <= 10'h000;
		else
			// MM write enable and LED address
			LEDR <= mm_we && (addr == 16'hC001) ? wdata[9:0] : LEDR[9:0];
			
	//always @(negedge clk, negedge rst_n)
	//	if(!rst_n)
	//		rdata <= 16'hbeef;
	//	else if (mm_re)
	//		// SW data is assigned to lower 10-bits of read data
	//		rdata <= {6'b000000, SW};
	//	else
	//		rdata <= 16'hbeef;
    
    assign SW_rdata = mm_re && (addr == 16'hC000) ? {6'b0, SW} : 16'hbeef;

//================================
//  SPART Access Signals
//================================

	// Reading a SPART register
	assign spart_read_reg_dec = (addr == 16'hC004 || addr == 16'hC005 || addr == 16'hC006 || addr == 16'hC007);
	// Writing a SPART register
	assign spart_write_reg_dec = (addr == 16'hC004 || addr == 16'hC006 || addr == 16'hC007); 
    
	// SPART selected when Address == 'hC004 || 'hC005 || 'hC006 || 'hC007
    // iocs_n is active low
    assign iocs_n = ~spart_read_reg_dec;
    
    // Read from SPART when MM_RE == 1 and address matched
    // Write to SPART when MM_WE == 1 and address matched
    assign iorw_n = (mm_re & spart_read_reg_dec) ? 1'b1 :
                    (mm_we & spart_write_reg_dec) ? 1'b0 : 1'b1;
    
    // Read Data from the SPART
    // 16'hC004 = Read from RX queue
    // 16'hC005 = SPART status register
    // 16'hC005 = SPART DB (Low) register
    // 16'hC005 = SPART SB (High) register
    assign SPART_rdata = mm_re && spart_read_reg_dec ? {8'h0, databus} : 16'hbeef;
    
    // Decode the IOADDR depending on the MM address used to access
    always @ (*) begin
        case (addr)
            // Buffer read/write
            16'hC004 : ioaddr = 'b00;
            // Status register read
            16'hC005 : ioaddr = 'b01;
            // DB (Low) write
            16'hC006 : ioaddr = 'b10;
            // DB (High) write
            16'hC007 : ioaddr = 'b11;
            default : ioaddr = 'b10;
        endcase
    end
    
	// Write to spart when IO write is enabled. Tri-buf since databus is a bi-directional bus.	
	assign databus = ~iorw_n ? wdata[7:0] : 8'hzz;

//========================================================
//  Module Instantiations
//========================================================

	// MUX the read data from pheripherals to the CPU
	// LED read 'hC000
	// SPART register reads 'hC00{4,5,6,7}
    assign rdata = mm_re && addr == 16'hC000 ? SW_rdata :
                   mm_re && spart_read_reg_dec ? SPART_rdata : 16'hbeef;
				   
	// Instantiate reset synchronizer
	rst_synch iRST(.RST_n(RST_n), .rst_n(rst_n), .clk(clk));
	
	// Instantiate CPU
	cpu iCPU(.rst_n(rst_n), .clk(clk), .wdata(wdata), .we(we), .addr(addr), .re(re), .rdata(rdata));
	
    // Instantiate SPART
    spart iSpart (
        .clk    (clk),
        .rst_n  (rst_n),
        .iocs_n (iocs_n),
        .iorw_n (iorw_n),
        .tx_q_full  (tx_q_full),
        .rx_q_empty (rx_q_empty),
        .ioaddr     (ioaddr),
        .databus    (databus),
        .TX         (TX),
        .RX         (RX)
    );

endmodule
