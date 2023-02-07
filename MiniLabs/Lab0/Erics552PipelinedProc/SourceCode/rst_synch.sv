module rst_synch (
    input wire clk, 
    input wire RST_n, 
    output logic rst_n
);

/////////////////////////////////////////////////////////////////
// Reset synchronizer that takes raw push button signal and   //
// creates a stable reset deasserted at negative edge of clk //
//////////////////////////////////////////////////////////////

//Intermediate signals between two flops
logic rst_n_q1;

//Producing a global reset (rst_n) which comes from double flopped design to account for metastability
always_ff @(negedge clk, negedge RST_n)
begin
	if(~RST_n)
		rst_n_q1 <= 'b0;
	else
		rst_n_q1 <= 'b1;
end

always_ff @(negedge clk, negedge RST_n) begin
	if(~RST_n) 
		rst_n <= 'b0;
	else
		rst_n <= rst_n_q1;
end

endmodule