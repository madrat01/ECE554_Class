module IM(clk,addr,rd_en,instr);

input clk;
input [13:0] addr;
input rd_en;			// asserted when instruction read desired

output reg [15:0] instr;	//output of insturction memory

reg [15:0]instr_mem[0:16383];

/////////////////////////////////////
// Memory is latched on clock low //
///////////////////////////////////
// 
// Read IM at the negedge clk. This instruction read is captured at ID the immediate posedge clk.
always @ (negedge clk)
  if (rd_en)
    instr <= instr_mem[addr];

initial begin
  $readmemh("spart_test.hex",instr_mem);
end

endmodule
