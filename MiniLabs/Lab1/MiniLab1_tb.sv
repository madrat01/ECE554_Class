module MiniLab1_tb();

	logic clk, rst_n;
	logic [9:0] LEDR, SW;
	
	// Initialize MiniLab0 module
	MiniLab1 iDUT(.clk(clk), .CLOCK2_50(1'b0), .CLOCK3_50(1'b0), .CLOCK4_50(1'b0), .RST_n(rst_n), .LEDR(LEDR), .SW(SW));
	
	initial begin
		// Non-reset initial mode
		rst_n = 1;
		clk = 0;
		repeat (10) @(posedge clk);
		// Reset
		rst_n = 0;
		// Initial switch value
		SW = 10'h155;
		repeat (10) @(posedge clk);
		// Get out of reset
    	rst_n = 1;
		// LED should capture the SW value 'h155
		repeat (10) @(posedge clk);
		if (LEDR == SW)
			$display("LED shows SW value! LEDR: %h", LEDR);
		else
			$display("Uhh! LED is faulty :)");
		repeat (10) @(posedge clk);
		SW = 10'h234;
		// LED should capture the SW value 'h234
		repeat (10) @(posedge clk);
		if (LEDR == SW)
			$display("LED shows SW value! LEDR: %h", LEDR);
		else
			$display("Uhh! LED is faulty :)");
		repeat (10) @(posedge clk);
		SW = 10'h377;
		// LED should capture the SW value 'h377
		repeat (10) @(posedge clk);
		if (LEDR == SW)
			$display("LED shows SW value! LEDR: %h", LEDR);
		else
			$display("Uhh! LED is faulty :)");
		@ (negedge clk);
		$stop();
	end

	always
		#5 clk = ~clk;

endmodule