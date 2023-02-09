module dualport_rf(clk,rst_n,p0_addr,p1_addr,p0,p1,re0,re1,dst_addr,dst,we,hlt);

	input clk;
	input rst_n;
	input [3:0] p0_addr, p1_addr;			// two read port addresses
	input re0,re1;							// read enables (power not functionality)
	input [3:0] dst_addr;					// write address
	input [15:0] dst;						// dst bus
	input we;								// write enable
	input hlt;								// not a functional input.  Used to dump register contents when
											// test is halted.

	output reg [15:0] p0,p1;  				//output read ports
	
	reg [15:0] prev_addr;
	reg prev_we;
	reg [15:0] prev_dst;

	// intermediary wires for the output of the register
	wire [15:0] p0_rf, p1_rf;
	
	// flop write data (we, dst, and dst_addr)
	always_ff @(negedge clk, negedge rst_n) begin
	    if (~rst_n) begin // reset values
			prev_addr <= 0;
			prev_we <= 0;
			prev_dst <= 0;
		end
		else begin
			prev_addr <= dst_addr;
			prev_we <= we;
			prev_dst <= dst;
		end
	end	
	
	// instantiate two register files
	rf iRF0(.clk(clk), .p0_addr(p0_addr), .p0(p0_rf), .re0(re0), .dst_addr(dst_addr), .dst(dst), .we(we), .hlt(hlt));
	rf iRF1(.clk(clk), .p0_addr(p1_addr), .p0(p1_rf), .re0(re1), .dst_addr(dst_addr), .dst(dst), .we(we), .hlt(hlt));

	// check if previous write is enabled, not writing to R0, and write address matches read address 
	// then forward previous write data, else use output from register file
	assign p0 = ~|p0_addr ? 'h0 :
                prev_we && (prev_addr == p0_addr) ? prev_dst : p0_rf;
	assign p1 = ~|p1_addr ? 'h0 :
                prev_we && (prev_addr == p1_addr) ? prev_dst : p1_rf;

endmodule
