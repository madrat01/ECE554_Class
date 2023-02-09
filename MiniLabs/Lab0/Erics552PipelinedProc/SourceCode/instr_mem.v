module IM(clk,addr,rd_en,instr);

input clk;
input [15:0] addr;
input rd_en;			// asserted when instruction read desired

output reg [15:0] instr;	//output of insturction memory

reg [15:0]instr_mem[0:65535];

/////////////////////////////////////
// Memory is latched on clock low //
///////////////////////////////////
// Previously :
// always @(addr,rd_en,clk)
//   if (~clk & rd_en)
// 
// Changed this to edge based capture.
// Read IM at the negedge clk. This instruction read is captured at ID the immediate posedge clk.
always @ (negedge clk)
  if (rd_en)
    instr <= instr_mem[addr];

initial begin
  $readmemh("C:/Users/acfra/Documents/ECE554/ECE554_Class/MiniLabs/Lab0/Erics552PipelinedProc/SourceCode/BasicOpCodes1.hex",instr_mem);
end

endmodule
