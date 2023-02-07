///////////////////////////////////////////////////////////////////////////////////////
// This module qualifies the write and read enable to DM and MM space.
// The qualification is done based on address accessed and we/re signals decoded by ID.
///////////////////////////////////////////////////////////////////////////////////////
module dm_qual (
    // Inputs
    input logic [2:0]   dst_EX_DM,      // MSB 3-bits of address used to access DN
    input logic         dm_we_EX_DM,    // DM write enable from ID

    // Outputs
    output logic        DM_we           // Qualified DM write enable
);

//////////// Address Map ///////////////////////
//  0xFFFF      |  
//  ..          |
//  ..          |   Memory mapped pheripherals
//  0xC001      |
//  0xC000      |
//  ..          |
//  ..          |
//  0x2000      |
//  --------------------------------------------
//  0x1FFF      |   
//  ..          |
//  ..          |   8k implemented SRAM
//  0x0001      |
//  0x0000      |
/////////////////////////////////////////////////

// Internal SRAM resides in lower 8k (MSB 3-bits will be zero)
// DM_we goes to DM to be used as write enable
assign DM_we = ~|dst_EX_DM & dm_we_EX_DM;

endmodule