//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: DE1_SOC board
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,				// 50MHz clk
    input rst_n,			// asynch active low reset
    input iocs_n,			// active low chip select (decode address range)
    input iorw_n,			// high for read, low for write
    output tx_q_full,		// indicates transmit queue is full
    output rx_q_empty,		// indicates receive queue is empty
    input [1:0] ioaddr,		// Read/write 1 of 4 internal 8-bit registers
    inout [7:0] databus,	// bi-directional data bus
    output TX,				// UART TX line
    input RX				// UART RX line
    );

typedef enum logic {IDLE, TRANSMIT} UART_TX_States_t;

// SPART Registers
logic [7:0] tx_rx_buffer_reg;   // Transmit Buffer and Recieve Buffer
logic [7:0] status_reg;         // SPART Status Register
logic [7:0] db_low_reg;         // Division Buffer (Low) Byte Register
logic [7:0] db_high_reg;        // Division Buffer (High) Byte Register

// RX and TX Buffer free and filled entries
logic [3:0] RX_free_entries, RX_filled_entries;  
logic [3:0] TX_free_entries, TX_filled_entries;  
logic       rx_q_full;
logic       tx_q_empty;

logic [7:0] RX_data_in, RX_data_out; // RX Buffer In and Out data
logic [7:0] RX_re, RX_we;            // RX Buffer read enable and write enable
logic [7:0] TX_data_in, TX_data_out; // TX Buffer In and Out data
logic [7:0] TX_re, TX_we;            // TX Buffer read enable and write enable

// UART RX signals
logic       UART_RX_RX;				 // rx is the asynch serial input (need to double flop)
logic       UART_RX_clr_rdy;		 // rdy can be cleared by this or n007 of new byte
logic       UART_RX_rdy;			 // signifies to core a byte has been received
logic [7:0] UART_RX_rx_data;		 // data that was received

// UART TX signals
logic       UART_TX_TX;                      // 
logic       UART_TX_trmt;
logic [7:0] UART_TX_tx_data;
logic       UART_TX_tx_done;
UART_TX_States_t tx_buf_read, tx_buf_read_nxt;


// Register Writes
always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        tx_rx_buffer_reg <= 8'h0;
        db_low_reg       <= 8'hB2;  // Default DB (Low)
        db_high_reg      <= 8'h01;  // Default DB (High)
    end
    else if (~iorw_n) begin
        case (ioaddr)
            2'b00 : tx_rx_buffer_reg <= databus;  
            2'b10 : db_low_reg       <= databus;
            2'b11 : db_high_reg      <= databus;
            default : ;
        endcase
    end
end

// Status Reg is a read-only register
// [7:4] Number of free entries in TX buffer
// [3:0] Number of filled entries in RX buffer
assign status_reg = {TX_free_entries, RX_filled_entries};

// Output TX from UART_TX
assign TX = UART_TX_TX;

UART_rx iUART_RX (
    // Inputs
    .clk        (clk),
    .rst_n      (rst_n),
    .RX         (UART_TX_RX),
    //.clr_rdy    (UART_RX_clr_rdy),
    .clr_rdy    (1'b0),
    // Outputs
    .rx_data    (UART_RX_rx_data),
    .rdy        (UART_RX_rdy)
);

// Assigning RX queue values
assign RX_data_in    = UART_RX_rx_data;             // Data written in RX is from UART_rx
assign RX_re         = iorw_n & ~|ioaddr;   // Read data from RXX when IO Read/Write is high and ioaddr matches the Buffer read/write register
assign RX_we         = UART_RX_rdy;                 // We are ready to write in the RX buffer when UART_RX asserts the ready signal

queue RX_BUF (
    // Inputs
    .clk            (clk),
    .rst_n          (rst_n),
    .in_data        (RX_data_in),
    .re             (RX_re),
    .we             (RX_we),
    // Outputs
    .out_data       (RX_data_out),
    .free_entries   (RX_free_entries),
    .filled_entries (RX_filled_entries),
    .empty          (rx_q_empty),
    .full           (rx_q_full)
);

assign UART_TX_trmt = ~tx_q_empty;  // Transmit to UART_TX when the TX buffer is not empty
assign UART_TX_tx_data = TX_data_out; // Data to the UART_TX from the buffer out data 

UART_tx iUART_TX (
    // Inputs
    .clk        (clk),
    .rst_n      (rst_n),
    .trmt       (UART_TX_trmt),
    .tx_data    (UART_TX_tx_data),
    // Outputs
    .tx_done    (UART_TX_tx_done),
    .TX         (UART_TX_TX)
);

assign TX_data_in = databus; 
assign TX_we = ~iorw_n & ~|ioaddr;

always_ff @ (posedge clk, negedge rst_n)
    if (~rst_n)
        tx_buf_read <= IDLE;
    else
        tx_buf_read <= tx_buf_read_nxt;

always_comb begin
    TX_re = 0;
    case (tx_buf_read)
        IDLE :  begin
                    tx_buf_read_nxt = ~tx_q_empty ? TRANSMIT : tx_buf_read;
                    TX_re = ~tx_q_empty ? 1'b1 : 1'b0;
                end
        TRANSMIT :  begin
                        TX_re = UART_TX_tx_done ? 1'b1 : 1'b0;
                        tx_buf_read_nxt = UART_TX_tx_done & tx_q_empty ? IDLE : tx_buf_read;
                    end
    endcase
end

queue TX_BUF (
    // Inputs
    .clk            (clk),
    .rst_n          (rst_n),
    .in_data        (TX_data_in),
    .re             (TX_re),
    .we             (TX_we),
    // Outputs
    .out_data       (TX_data_out),
    .free_entries   (TX_free_entries),
    .filled_entries (TX_filled_entries),
    .empty          (tx_q_empty),
    .full           (tx_q_full)
);
				   
endmodule
