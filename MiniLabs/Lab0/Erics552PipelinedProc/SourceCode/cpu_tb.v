module cpu_tb();

reg clk,rst_n;
wire [15:0]	rdata;	// MM read data from switches

wire [15:0]	addr;	  // Address to access memory-mapped space
wire re;		        // MM read enable to the switches
wire we;		        // MM write enable to the LED
wire [15:0] wdata;	// MM write data to the LED

//////////////////////
// Instantiate CPU //
////////////////////
cpu iCPU(.clk(clk), .rst_n(rst_n), .rdata(rdata), .addr(addr), .re(re), .we(we), .wdata(wdata));

initial begin
  clk = 0;
  rst_n = 0;
  #2 rst_n = 1;
end
  
always
  #1 clk = ~clk;
  
endmodule