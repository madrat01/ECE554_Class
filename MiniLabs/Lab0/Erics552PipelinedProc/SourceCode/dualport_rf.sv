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

	wire [15:0] p0_rf, p1_rf;
	
	always_ff @(negedge clk) begin
	    if (~rst_n) begin
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
	
	rf iRF0(.clk(clk), .p0_addr(p0_addr), .p0(p0_rf), .re0(re0), .dst_addr(dst_addr), .dst(dst), .we(we), .hlt(hlt));
	rf iRF1(.clk(clk), .p0_addr(p1_addr), .p0(p1_rf), .re0(re1), .dst_addr(dst_addr), .dst(dst), .we(we), .hlt(hlt));

	assign p0 = prev_we && (prev_addr == p0_addr) ? prev_dst : p0_rf;
	assign p1 = prev_we && (prev_addr == p1_addr) ? prev_dst : p1_rf;

endmodule