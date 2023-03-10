module rf(clk,p0_addr,p0,re0,dst_addr,dst,we,hlt);
//////////////////////////////////////////////////////////////////
// Triple ported register file.  Two read ports (p0 & p1), and //
// one write port (dst).  Data is written on clock high, and  //
// read on clock low //////////////////////////////////////////
//////////////////////

input clk;
input [3:0] p0_addr;			// two read port addresses
input re0;							// read enables (power not functionality)
input [3:0] dst_addr;					// write address
input [15:0] dst;						// dst bus
input we;								// write enable
input hlt;								// not a functional input.  Used to dump register contents when
										// test is halted.

output reg [15:0] p0;  				//output read ports

integer indx;

reg [15:0]mem[0:15];					// 16 registers each 16-bit wide

//////////////////////////////////////////////////////////
// Register file will come up uninitialized except for //
// register zero which is hardwired to be zero.       //
///////////////////////////////////////////////////////
//Comment the initial block for synthesizable design
//initial begin
//  $readmemh("C:/Users/erichoffman/Documents/ECE_Classes/ECE552/EricStuff/Project/Tests/rfinit.txt",mem);
//  mem[0] is now always written in the always block 
//  mem[0] = 16'h0000;					// reg0 is always 0,
//end

//////////////////////////////////
// RF is written on negedge clock //
////////////////////////////////
always @(negedge clk) begin
  if (we && |dst_addr)
    mem[dst_addr] <= dst;
end
	
//////////////////////////////
// RF is read on negedge clock //
////////////////////////////
always @(negedge clk)
  if (re0)
    p0 <= mem[p0_addr];
	
////////////////////////////////////////
// Dump register contents at program //
// halt for debug purposes          //
/////////////////////////////////////
always @(posedge hlt)
  for(indx=1; indx<16; indx = indx+1)
    $display("R%1h = %h",indx,mem[indx]);
	
endmodule
  

