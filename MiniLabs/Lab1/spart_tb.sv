module spart_tb;

logic       clk;
logic       rst_n;
wire  [7:0] databus_in;     // An 8-bit, 3-state bidirectional bus used to transfer data and control information between the Processor and the SPART.
logic [7:0] databus;        // An 8-bit, 3-state bidirectional bus used to transfer data and control information between the Processor and the SPART.
logic [7:0] databus_tb;     // An 8-bit, 3-state bidirectional bus used to transfer data and control information between the Processor and the SPART.
logic [1:0] ioaddr;         // A 2-bit address bus used to select the particular register that interacts with the databus during an I/O operation
logic       iorw_n;         // Determines the direction of data transfer between the Processor and SPART. For a read (iorw_n=1), data is transferred from the SPART to the Processor and for a write (iorw_n=0), data is transferred from the processor to the SPART
logic       iocs_n;         // Active low chip select. Writes or reads to registers have no effect unless active
logic       rx_q_empty;     // If 1 then no receive data present to read
logic       tx_q_full;      // If 1 then transmit queue is full and cannot accept anymore bytes
logic       TX;			    // UART TX line
logic       RX;			    // UART RX line
int         baud_rate_cycles;

// Instantiate spart module
spart iSpart (
    .clk    (clk),
    .rst_n  (rst_n),
    .iocs_n (iocs_n),
    .iorw_n (iorw_n),
    .tx_q_full  (tx_q_full),
    .rx_q_empty (rx_q_empty),
    .ioaddr     (ioaddr),
    .databus    (databus_in),
    .TX         (TX),
    .RX         (RX)
);

assign RX = TX;

assign databus_in = ~iorw_n ? databus : 8'hz;

initial begin
    clk = 0;
    // Non-reset mode
    rst_n = 1;
    baud_rate_cycles = 'd40000;
    // Defaut to buffer read mode so that we don't write unnecessarily
    iorw_n = 1;
    // Default to not selecting spart
    iocs_n = 1;
    repeat (2) @ (negedge clk);
    // Assert reset
    rst_n = 0;
    // Chip select
    select_spart(iocs_n);
    databus = 'h66;
    repeat (2) @ (negedge clk);
    // Come out of reset
    rst_n = 1;
    // Set up the buffer to read and write
    select_buffer_rd_wr(ioaddr);
    repeat (2) @ (negedge clk);
    ///////////////////////////////////////////////////////////
    // Fully write the TX buffer and read the RX buffer
    ///////////////////////////////////////////////////////////
    $display("========= Start Stressing TX and RX Buffer ===========");
    stress_rd_wr_buffer(clk, ioaddr, iorw_n, iocs_n, tx_q_full, rx_q_empty, databus, baud_rate_cycles);
    $display("========= End Stressing TX and RX Buffer ===========");
    ///////////////////////////////////////////////////////////
    // Read and write with different baud rates
    ///////////////////////////////////////////////////////////
    $display("========= Start Accessing TX and RX Buffer with dassertferent Baud rates ===========");
    random_rd_wr_buffer(clk, ioaddr, iorw_n, tx_q_full, rx_q_empty, databus);
    $display("========= End Accessing TX and RX Buffer with dassertferent Baud rates ===========");
    repeat (2) @ (negedge clk);
    ///////////////////////////////////////////////////////////
    // Change Baud Rate and test read and write to the buffer
    ///////////////////////////////////////////////////////////
    $display("========= Start Baud Rate Change Test ===========");
    // Change baud rate to h'0036.
	baud_rate_cycles = 'd10000;
    @ (negedge clk);
    select_db_low_div_buffer_write(ioaddr, iorw_n);
    databus = 'h36;
    @ (negedge clk);
    select_db_high_div_buffer_write(ioaddr, iorw_n);
    databus = 'h00;
    @ (negedge clk);
    // Fully write and read the buffer. The RX buffer should fill much faster than before since the transmission has a higher baud rate.
    stress_rd_wr_buffer(clk, ioaddr, iorw_n, iocs_n, tx_q_full, rx_q_empty, databus, baud_rate_cycles);
    $display("========== End Baud Rate Change Test ===========");
    @ (negedge clk);
    ///////////////////////////////////////////////////////////
    // Unselect spart and write/read to the various registers
    ///////////////////////////////////////////////////////////
    $display("========== Start Un-Select SPART Test ===========");
    unselect_spart_test(iocs_n, ioaddr, iorw_n, databus);
    $display("====== End Un-Select SPART Test =======");
    @ (negedge clk);    
    $stop();
end

always @ (databus_in)
    databus <= databus_in;

always begin
    #100 clk = ~clk;
end

// Tasks to stress spart

// Stress write and read of the buffer
task automatic stress_rd_wr_buffer (ref logic clk, ref logic [1:0] ioaddr, ref logic iorw_n, ref logic iocs_n, ref logic tx_q_full, ref logic rx_q_empty, ref logic [7:0] databus, input int baud_rate_cycles);
    logic [7:0] buffer_data [$:7];
    logic [7:0] buffer_front;
    // Write buffer till the queue is full
    while (~tx_q_full) begin
        @ (negedge clk);
        // Select the buffer read/write ioaddr
        select_buffer_rd_wr(ioaddr);
        // Call task to write the buffer
        write_spart_buffer (iorw_n, databus);
        // Capture the written data which will be used in the self check when we read the buffer 
        if (~tx_q_full)
            buffer_data = {buffer_data, databus};
    end
    $display("Buffered data %p", buffer_data);
    @ (negedge clk);
    // Read the buffer status to determine is TX queue has data
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[7:4] < 'd8)
        $display("PASS! TX Queue has data!");     
    else
        $error("ERROR! TX Queue has no data!");
    
    // Start to read the RX queue
    repeat (baud_rate_cycles) @ (negedge clk);
    // Read the buffer status to determine is RX queue is full
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[3:0] == 8)
        $display("PASS! RX Queue is full!");     
    else
        $error("ERROR! RX Queue is not full!");
    select_buffer_rd_wr(ioaddr);
    // Read buffer till the queue is empty
    while (~rx_q_empty) begin
        @ (negedge clk);
        // Call task to read the buffer
        read_spart_buffer (iorw_n);
        // The read happens at the posedge
        @ (posedge clk);
        // Compare the buffered data and the data we wrote
        buffer_front = buffer_data.pop_front();
        if (~rx_q_empty)
            assert (buffer_front == databus)
                $display("PASS! Succuesfully read data from the buffer, READ DATA = %d", databus);
            else
                $error("ERROR! Read and write data mismatch, READ DATA = %d, WRITE DATA = %d", databus, buffer_front);
    end
    @ (negedge clk);
    // Read the buffer status to confirm that the RX queue is empty
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[3:0] == 0)
        $display("PASS! RX Queue is Empty!");     
    else
        $error("ERROR! RX Queue is not Empty!");
    select_buffer_rd_wr(ioaddr);
endtask 

// Write and read at different baud rates
task automatic random_rd_wr_buffer (ref logic clk, ref logic [1:0] ioaddr, ref logic iorw_n, ref logic tx_q_full, ref logic rx_q_empty, ref logic [7:0] databus);
    logic [7:0] buffer_data [$:7];
    logic [7:0] buffer_front;
    while (~tx_q_full) begin
        @ (negedge clk);
        // Select the buffer read/write ioaddr
        select_buffer_rd_wr(ioaddr);
        write_spart_buffer(iorw_n, databus);
        // Capture the written data which will be used in the self check when we read the buffer 
        if (~tx_q_full)
            buffer_data = {buffer_data, databus};
    end
    $display("Buffered data %p", buffer_data);
    @ (negedge clk);
    // Read the buffer status
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[7:4] < 'd8)
        $display("PASS! TX Queue has data!");     
    else
        $error("ERROR! TX Queue has no data!");
    @ (negedge clk);
    // change baud rate
    select_db_low_div_buffer_write(ioaddr, iorw_n);
    databus = 'hd9;
    @ (negedge clk);
    select_db_high_div_buffer_write(ioaddr, iorw_n);
    databus = 'h00; 
    @ (negedge clk);
    // The RX queue is filled faster than the default since the baud rate has increased
    repeat (20000) @ (negedge clk);
    // Read the buffer status to determine is RX queue is full
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[3:0] == 8)
        $display("PASS! RX Queue is full! The Baud Rate increase has worked!");     
    else
        $error("ERROR! RX Queue is not full! Umm Baud Rate Why??");
    // Select the buffer read/write ioaddr
    select_buffer_rd_wr(ioaddr);
    while (~rx_q_empty) begin
        @ (negedge clk);
        read_spart_buffer(iorw_n);
        @ (posedge clk);
        // Compare the buffered data and the data we wrote
        buffer_front = buffer_data.pop_front();
        if (~rx_q_empty)
            assert (buffer_front == databus)
                $display("PASS! Succuesfully read data from the buffer, READ DATA = %d", databus);
            else
                $error("ERROR! Read and write data mismatch, READ DATA = %d, WRITE DATA = %d", databus, buffer_front);
    end 
endtask

// Unselect SPART and test change of:
// 1. Baud Register
// 2. Status Register
// 3. Write to the buffer
task automatic unselect_spart_test(ref logic iocs_n, ref logic [1:0] ioaddr, ref logic iorw_n, ref logic [7:0] databus);
    logic [7:0] prev_status_reg_value;
    // Unselect the spart and change the baud rate register. Read back data and check if the write has gone through.
    unselect_spart(iocs_n);
    @ (negedge clk);
    select_db_low_div_buffer_write(ioaddr, iorw_n);
    databus = 'h64;
    @ (negedge clk);
    // Probe the register directly and check if the value has been written
    assert (iSpart.db_low_reg[7:0] === 'h36)
        $display("PASS! DB (Low) register is not written when chip is unselected");
    else
        $error("FAIL! DB (Low) register is written even when chip is unselected");
    // Read from the data bus and check if we are expecting zzz. 
    select_db_low_div_buffer_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[7:0] === 'z)
        $display("PASS! DB (Low) register read has not gone through");
    else
        $error("FAIL! DB (Low) register read has gone through");
    @ (negedge clk);
    select_db_high_div_buffer_write(ioaddr, iorw_n);
    databus = 'h03;
    @ (negedge clk);
    // Probe the register directly and check if the value has been written
    assert (iSpart.db_high_reg[7:0] === 'h00)
        $display("PASS! DB (High) register is not written when chip is unselected");
    else
        $error("FAIL! DB (High) register is written even when chip is unselected");
    select_db_high_div_buffer_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus[7:0] === 'z)
        $display("PASS! DB (High) register read has not gone through");
    else
        $error("FAIL! DB (High) register read gone through");
    @ (negedge clk);
    // Unselect the spart and read the status register. The databus should not contain a value, only zzzz.
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (databus === 'z)
        $display("PASS! Status register read shouldn't have gone through. Output zz. Actual %h", iSpart.status_reg);
    else
        $error("FAIL! Status register read has gone through. Output value %h", databus);
    prev_status_reg_value = iSpart.status_reg;
    // Write to the TX buffer should also not go through
    // Select the buffer read/write ioaddr
    select_buffer_rd_wr(ioaddr);
    // Call task to write the buffer
    write_spart_buffer (iorw_n, databus);
    @ (negedge clk);
    // Unselect the spart and read the status register. The databus should not contain a value, only zzzz.
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    assert (iSpart.status_reg === prev_status_reg_value)
        $display("PASS! Write of the TX buffer has not gone through. Status reg is still the same value %h", prev_status_reg_value);
    else
        $error("FAIL! Write of the TX buffer has gone through. Status regiser changed to %h from %h", iSpart.status_reg, prev_status_reg_value);
    @ (negedge clk);
endtask

// Write the buffer
task automatic write_spart_buffer (ref logic iorw_n, ref logic [7:0] databus);
    iorw_n = 0;
    databus = $urandom();
endtask

// Read the buffer
task automatic read_spart_buffer (ref logic iorw_n);
    iorw_n = 1;
endtask

// This task selects the SPART - SPART registers can be read and written
task automatic select_spart (ref logic iocs_n);
    iocs_n = 0;
endtask

// This task un-selects the SPART - SPART registers can't re read and written
task automatic unselect_spart (ref logic iocs_n);
    iocs_n = 1;
endtask

// This task selects buffer read and write operation
task automatic select_buffer_rd_wr (ref logic [1:0] ioaddr);
    ioaddr = 'b00;
endtask

// This task selects status register read
task automatic select_status_register_read (ref logic [1:0] ioaddr, ref logic iorw_n);
    iorw_n = 'b1;
    ioaddr = 'b01;
endtask

// This task selects DB low division buffer
task automatic select_db_low_div_buffer_write (ref logic [1:0] ioaddr, ref logic iorw_n);
    iorw_n = 'b0;
    ioaddr = 'b10;
endtask

// This task selects SB high division buffer
task automatic select_db_high_div_buffer_write (ref logic [1:0] ioaddr, ref logic iorw_n);
    iorw_n = 'b0;
    ioaddr = 'b11;
endtask

// This task selects DB low division buffer
task automatic select_db_low_div_buffer_read (ref logic [1:0] ioaddr, ref logic iorw_n);
    iorw_n = 'b1;
    ioaddr = 'b10;
endtask

// This task selects SB high division buffer
task automatic select_db_high_div_buffer_read (ref logic [1:0] ioaddr, ref logic iorw_n);
    iorw_n = 'b1;
    ioaddr = 'b11;
endtask

endmodule
