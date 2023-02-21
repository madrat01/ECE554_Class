module MiniProject1_tb();

	logic           clk;
    logic           rst_n;
	logic [9:0]     LEDR;
    wire            TX, RX;
    wire  [35:0]    GPIO;
	
	// Initialize MiniProject1 module
	MiniProject1 iDUT(.clk(clk), .CLOCK2_50(1'b0), .CLOCK3_50(1'b0), .CLOCK4_50(1'b0), .RST_n(rst_n), .LEDR(LEDR), .GPIO(GPIO), .TX(TX), .RX(RX));
	
	initial begin
		// Non-reset initial mode
		rst_n = 1;
		clk = 0;
		repeat (10) @(posedge clk);
		// Reset
		rst_n = 0;
		repeat (10) @(posedge clk);
		// Get out of reset
    	rst_n = 1;
		// LED should capture the SW value 'h155
		repeat (800000) @(posedge clk);
		@ (negedge clk);
		$stop();
	end

	always
		#5 clk = ~clk;

endmodule
