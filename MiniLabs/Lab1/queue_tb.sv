module queue_tb();
	logic clk, rst_n;
	logic [7:0] in_data, out_data;
	logic re, we;
	logic empty, full;
	
	queue iDUT(.clk(clk), .rst_n(rst_n), .in_data(in_data), .re(re), .we(we), .out_data(out_data), .free_entries(), .filled_entries(), .empty(), .full());

	initial begin
		clk = 0;
		rst_n = 0;
		re = 0;
		we = 0;
		in_data = 8'h00;
		
		@(posedge clk);
		@(negedge clk);
		rst_n = 1; // deassert reset
		
		write(clk, in_data, we, 8'h00);
		
		write(clk, in_data, we, 8'h01);
		
		write(clk, in_data, we, 8'h02);
		
		write(clk, in_data, we, 8'h03);
		
		write(clk, in_data, we, 8'h04);
		
		write(clk, in_data, we, 8'h05);
		
		write(clk, in_data, we, 8'h06);
		
		write(clk, in_data, we, 8'h07);
		
		write(clk, in_data, we, 8'h08);
		
		read(clk, re);
		
		write(clk, in_data, we, 8'h08);
		
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		read(clk, re);
		
		@(posedge clk);
		$stop;
	end

	always
		#5 clk = ~clk;
		
	task automatic write(ref clk, ref [7:0] in_data, ref we, input [7:0] write_data);
		begin
			@(posedge clk);
			in_data = write_data;
			we = 1;
			@(posedge clk);
			we = 0;
		end
	endtask
	
	task automatic read(ref clk, ref re);
		begin
			@(posedge clk);
			re = 1;
			@(posedge clk);
			re = 0;
		end
	endtask
endmodule