module MiniLab0_tb();

	logic clk, rst_n;
	logic [9:0] LEDR, SW;
	MiniLab0 iDUT(.clk(clk), .KEY0(rst_n), .LEDR(LEDR), .SW(SW));
	
	initial begin
		rst_n = 1;
		clk = 0;
		repeat (100) @(posedge clk);
		rst_n = 0;
		SW = 10'h155;
		repeat (100) @(posedge clk);
    		rst_n = 1;
		$display("LEDR: %h", LEDR);
		repeat (10) @(posedge clk);
		SW = 10'hAFF;
		$display("LEDR: %h", LEDR);
		repeat (10) @(posedge clk);
		SW = 10'h6FF;
		$display("LEDR: %h", LEDR);
		repeat (200) @(posedge clk);
		//$stop();
	end

	always
		#5 clk = ~clk;

endmodule;