module cpu	(
	input wire			clk,
	input wire			rst_n,
	input wire [15:0]	rdata,	// MM read data from switches
	input wire			mm_re,	// Receiving data from MM

	output wire [15:0]	addr,	// Address to access memory-mapped space
	output wire			re,		// MM read enable to the switches
	output wire 		we,		// MM write enable to the LED
	output wire	[15:0]  wdata	// MM write data to the LED
);

wire [15:0] instr;				// instruction from IM
wire [11:0] instr_ID_EX;		// immediate bus
wire [15:0] src0,src1;			// operand busses into ALU
wire [15:0] dst_EX_DM;			// result from ALU
wire [15:0] dst_ID_EX;			// result from ALU for branch destination
wire [15:0] pc_ID_EX;			// nxt_pc to source mux for JR
wire [15:0] pc_EX_DM;			// nxt_pc to store in reg15 for JAL
wire [15:0] iaddr;				// instruction address
wire [15:0] dm_rd_data_EX_DM;	// data memory read data
wire [15:0] dm_mm_rd_data_EX_DM;// muxed data between DM and MM read data
wire [15:0] rf_w_data_DM_WB;	// register file write data
wire [15:0] p0,p1;				// read ports from RF
wire [3:0] rf_p0_addr;			// address for port 0 reads
wire [3:0] rf_p1_addr;			// address for port 1 reads
wire [3:0] rf_dst_addr_DM_WB;	// address for RF write port
wire [2:0] alu_func_ID_EX;		// specifies operation ALU should perform
wire [1:0] src0sel_ID_EX;		// select for src0 bus
wire [1:0] src1sel_ID_EX;		// select for src1 bus
wire [2:0] cc_ID_EX;			// condition code pipeline from instr[11:9]
wire [15:0] p0_EX_DM;			// data to be stored for SW
wire DM_we;          			// Qualified DM write enable

//////////////////////////////////
// Instantiate program counter //
////////////////////////////////
pc iPC(.clk(clk), .rst_n(rst_n), .stall_IM_ID(stall_IM_ID), .pc(iaddr), .dst_ID_EX(dst_ID_EX),
       .pc_ID_EX(pc_ID_EX), .pc_EX_DM(pc_EX_DM), .flow_change_ID_EX(flow_change_ID_EX));
	   
/////////////////////////////////////
// Instantiate instruction memory //
///////////////////////////////////
IM iIM(.clk(clk), .addr(iaddr), .rd_en(1'b1), .instr(instr));

//////////////////////////////////////////////
// Instantiate register instruction decode //
////////////////////////////////////////////
id	iID(.clk(clk), .rst_n(rst_n), .instr(instr), .zr_EX_DM(zr_EX_DM), .br_instr_ID_EX(br_instr_ID_EX),
        .jmp_imm_ID_EX(jmp_imm_ID_EX), .jmp_reg_ID_EX(jmp_reg_ID_EX), .jmp_imm_EX_DM(jmp_imm_EX_DM), .rf_re0(rf_re0),
		.rf_re1(rf_re1), .rf_we_DM_WB(rf_we_DM_WB), .rf_p0_addr(rf_p0_addr), .rf_p1_addr(rf_p1_addr),
		.rf_dst_addr_DM_WB(rf_dst_addr_DM_WB), .alu_func_ID_EX(alu_func_ID_EX),
		.src0sel_ID_EX(src0sel_ID_EX), .src1sel_ID_EX(src1sel_ID_EX), .dm_re_EX_DM(dm_re_EX_DM),
		.dm_we_EX_DM(dm_we_EX_DM), .clk_z_ID_EX(clk_z_ID_EX), .clk_nv_ID_EX(clk_nv_ID_EX),
		.instr_ID_EX(instr_ID_EX), .cc_ID_EX(cc_ID_EX), .stall_IM_ID(stall_IM_ID),
		.stall_ID_EX(stall_ID_EX), .stall_EX_DM(stall_EX_DM), .hlt_DM_WB(hlt_DM_WB),
		.byp0_EX(byp0_EX), .byp0_DM(byp0_DM)/*, .byp0_WB(byp0_WB)*/, .byp1_EX(byp1_EX), .byp1_DM(byp1_DM),// .byp1_WB(byp1_WB),
		.flow_change_ID_EX(flow_change_ID_EX));
	   
////////////////////////////////
// Instantiate register file //
//////////////////////////////
dualport_rf iRF(.clk(clk), .rst_n(rst_n), .p0_addr(rf_p0_addr), .p1_addr(rf_p1_addr), .p0(p0), .p1(p1),
       .re0(rf_re0), .re1(rf_re1), .dst_addr(rf_dst_addr_DM_WB), .dst(rf_w_data_DM_WB),
 	   .we(rf_we_DM_WB), .hlt(hlt_DM_WB));
	   
///////////////////////////////////
// Instantiate register src mux //
/////////////////////////////////
src_mux ISRCMUX(.clk(clk), .stall_ID_EX(stall_ID_EX), .stall_EX_DM(stall_EX_DM),
                .src0sel_ID_EX(src0sel_ID_EX), .src1sel_ID_EX(src1sel_ID_EX), .p0(p0), .p1(p1),
                .imm_ID_EX(instr_ID_EX), .pc_ID_EX(pc_ID_EX), .p0_EX_DM(p0_EX_DM),
				.src0(src0), .src1(src1), .dst_EX_DM(dst_EX_DM), .dst_DM_WB(rf_w_data_DM_WB), //.dst_WB(rf_w_data_DM_WB), 
			    .byp0_EX(byp0_EX), .byp0_DM(byp0_DM)/*, .byp0_WB(byp0_WB)*/, .byp1_EX(byp1_EX), .byp1_DM(byp1_DM)/*, .byp1_WB(byp1_WB)*/);
	   
//////////////////////
// Instantiate ALU //
////////////////////
alu iALU(.clk(clk), .src0(src0), .src1(src1), .shamt(instr_ID_EX[3:0]), .func(alu_func_ID_EX),
         .dst(dst_ID_EX), .dst_EX_DM(dst_EX_DM), .ov(ov), .zr(zr), .neg(neg));		   


/////////////////////////
// Instantiate DM Qual //
/////////////////////////
dm_qual iDMQ(
	// Inputs
	.dst_EX_DM		(dst_EX_DM[15:13]),	// Upper 3-bits used to qualify the DM address space we write
	.dm_we_EX_DM	(dm_we_EX_DM), 

	// Outputs
	.DM_we			(DM_we)
);

// Address to access MM space
assign addr = dst_EX_DM;

// Write enable to MM space
assign we 	= dm_we_EX_DM;

// Write data to MM space
assign wdata = p0_EX_DM;

// Read enable to MM space
assign re   = dm_re_EX_DM;

//////////////////////////////
// Instantiate data memory //
////////////////////////////
DM iDM(.clk(clk),.addr(dst_EX_DM), .re(dm_re_EX_DM), .we(DM_we), .wrt_data(p0_EX_DM),
       .rd_data(dm_rd_data_EX_DM));

// We can get data from MM or DM. mm_re is high when we are receiving data from MM.
// Mux MM rdata and dm_rd_data_EX_DM
// Output to iDSTMUX
assign dm_mm_rd_data_EX_DM = mm_re ? rdata : dm_rd_data_EX_DM; 

//////////////////////////
// Instantiate dst mux //
////////////////////////
dst_mux iDSTMUX(.clk(clk), .dm_re_EX_DM(dm_re_EX_DM), .dm_rd_data_EX_DM(dm_mm_rd_data_EX_DM),
                .dst_EX_DM(dst_EX_DM), .pc_EX_DM(pc_EX_DM), .rf_w_data_DM_WB(rf_w_data_DM_WB),
				.jmp_imm_EX_DM(jmp_imm_EX_DM));
	
/////////////////////////////////////////////
// Instantiate branch determination logic //
///////////////////////////////////////////
br_bool iBRL(.clk(clk), .rst_n(rst_n), .clk_z_ID_EX(clk_z_ID_EX), .clk_nv_ID_EX(clk_nv_ID_EX),
             .br_instr_ID_EX(br_instr_ID_EX), .jmp_imm_ID_EX(jmp_imm_ID_EX),
			 .jmp_reg_ID_EX(jmp_reg_ID_EX), .cc_ID_EX(cc_ID_EX), .zr(zr), .ov(ov),
			 .zr_EX_DM(zr_EX_DM), .neg(neg), .flow_change_ID_EX(flow_change_ID_EX));	
	   
endmodule