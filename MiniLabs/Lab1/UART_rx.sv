module UART_rx(input clk, input rst_n, input RX, input clr_rdy, input [12:0]baud_rate, output [7:0]rx_data, output logic rdy);
	// internal signals
	logic start, shift, receiving, set_rdy;
	logic [3:0] bit_cnt;
	logic [12:0] baud_cnt;
	logic [8:0] rx_shft_reg;
	logic rx_f1, rx_f2, rdy_in;
	
	// states
	typedef enum {IDLE, RECIEVE} state_t;
	state_t state, nxt_state;
	
	// shift when baud_cnt reaches 0 (shift at the baud rate)
	assign shift = baud_cnt == 0 ? 1'b1 : 1'b0;
	
	// shift reg mux and flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rx_shft_reg <= 9'b111111111;
		else if(shift) // if shifting, shift in new bit
			rx_shft_reg <= {rx_f2, rx_shft_reg[8:1]};
		else // otherwise maintain
			rx_shft_reg <= rx_shft_reg;
	assign rx_data = rx_shft_reg[7:0];
		
	// bit_cnt mux and flop
	// needs to shift in 10 bits
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			bit_cnt <= 0;
		else if(start) // reset bit_cnt when starting a new recieve
			bit_cnt <= 0;
		else if(shift) // increment bit_cnt when shifting
			bit_cnt <= bit_cnt + 1;
		else
			bit_cnt <= bit_cnt;	
		
	// baud_cnt mux and flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			baud_cnt <= 0;
		else if(start)
			baud_cnt <= baud_rate >> 1;
		else if(shift)
			baud_cnt <= baud_rate;
		else if(receiving)
			baud_cnt <= baud_cnt - 1;
		else
			baud_cnt <= baud_cnt;

	// double flop for RX input
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rx_f1 <= 1;
		else
			rx_f1 <= RX;
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rx_f2 <= 1;
		else
			rx_f2 <= rx_f1;
	
	// asserting rdy
	// assures rdy is only set for one cycle 
	//(only when set_rdy is set when transitioning back to IDLE)
	assign rdy_in = start ? 0 :
					clr_rdy ? 0 :
					set_rdy ? 1 :
					0;
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rdy <= 0;
		else
			rdy <= rdy_in;
			
		
	// state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;		
	// FSM
	always_comb begin
		nxt_state <= state;
		start <= 0;
		receiving <= 0;
		set_rdy <= 0;
		case(state)
			IDLE: begin
				if(!rx_f2) begin
					nxt_state <= RECIEVE;
					start <= 1;
				end
			end
			RECIEVE: begin
				receiving <= 1;
				if(bit_cnt == 10) begin // finished when 10 bits are recieved
					set_rdy <= 1;
					receiving <= 0;
					nxt_state <= IDLE;
				end
			end
		endcase
	end
endmodule
