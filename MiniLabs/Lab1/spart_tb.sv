module spart_tb;

logic       clk;
logic       rst_n;
logic [7:0] databus;        // An 8-bit, 3-state bidirectional bus used to transfer data and control information between the Processor and the SPART.
logic [1:0] ioaddr;         // A 2-bit address bus used to select the particular register that interacts with the databus during an I/O operation
logic       iorw_n;         // Determines the direction of data transfer between the Processor and SPART. For a read (iorw_n=1), data is transferred from the SPART to the Processor and for a write (iorw_n=0), data is transferred from the processor to the SPART
logic       iocs_n;         // Active low chip select. Writes or reads to registers have no effect unless active
logic       rx_q_empty;     // If 1 then no receive data present to read
logic       tx_q_full;      // If 1 then transmit queue is full and cannot accept anymore bytes

// Instantiate spart module
//spart iSpart ();

initial begin
    clk = 0;
    // Non-reset mode
    rst_n = 1;
    repeat (2) @ (negedge clk);
    // Assert reset
    rst_n = 0;
    // Defaut to buffer read mode so that we don't write unnecessarily
    iorw_n = 1;
    // Default to chip select
    select_spart(iocs_n);
    databus = 'h66;
    repeat (2) @ (negedge clk);
    // Come out of reset
    rst_n = 1;
    // Set up the buffer to read and write
    select_buffer_rd_wr(ioaddr);
    repeat (2) @ (negedge clk);
    // Fully write and read the buffer
    stress_rd_wr_buffer(clk, ioaddr, iorw_n, tx_q_full, rx_q_empty, databus);
    // Read and write with different baud rates
    random_rd_wr_buffer(clk, ioaddr, iorw_n, tx_q_full, rx_q_empty, databus);
    repeat (2) @ (negedge clk);
    // TODO Baud Rate Configuration
    // TODO unselect chip and try changing the register, reading from buffers and registers
end

always begin
    #10000 clk = ~clk;
end

// Tasks to stress spart

// Stress write and read of the buffer
task automatic stress_rd_wr_buffer (ref logic clk, ref logic [1:0] ioaddr, ref logic iorw_n, ref logic tx_q_full, ref logic rx_q_empty, ref logic [7:0] databus);
    logic [7:0] buffer_data [$:8];
    logic [7:0] buffer_front;
    // Write buffer till the queue is full
    while (~tx_q_full) begin
        @ (negedge clk);
        // Call task to write the buffer
        write_spart_buffer (iorw_n, databus);
        // Capture the written data which will be used in the self check when we read the buffer 
        buffer_data = {buffer_data, databus};
    end
    @ (negedge clk);
    // Read the buffer status
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    if (databus[7:4] == 0)
        $display("PASS! TX Queue is full!");     
    else
        $display("ERROR! TX Queue is not full!");
    // Start to read the RX queue after TODO cycles
    repeat (100) @ (negedge clk);
    // Read the buffer status
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    if (databus[3:0] == 8)
        $display("PASS! RX Queue is full!");     
    else
        $display("ERROR! RX Queue is not empty!");
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
        if (buffer_front == databus)
            $display("Succuesfully read data from the buffer, READ DATA = %h", databus);
        else
            $display("Read and write data mismatch, READ DATA = %h, WRITE DATA = %h", databus, buffer_front);
    end
    @ (negedge clk);
    // Read the buffer status
    select_status_register_read(ioaddr, iorw_n);
    @ (posedge clk);
    if (databus[3:0] == 0)
        $display("PASS! RX Queue is Empty!");     
    else
        $display("ERROR! RX Queue is not empty!");
    select_buffer_rd_wr(ioaddr);
endtask 

// Write and read at different baud rates
task automatic random_rd_wr_buffer (ref logic clk, ref logic [1:0] ioaddr, ref logic iorw_n, ref logic tx_q_full, ref logic rx_q_empty, ref logic [7:0] databus);
    logic [7:0] buffer_data [$:8];
    logic [7:0] buffer_front;
    while (~tx_q_full) begin
        @ (negedge clk);
        write_spart_buffer(iorw_n, databus);
        // Capture the written data which will be used in the self check when we read the buffer 
        buffer_data = {buffer_data, databus};
    end
    @ (negedge clk);
    // Read the buffer status
    select_status_register_read(ioaddr, iorw_n);
    @ (negedge clk);
    // TODO change baud rate
    select_db_low_div_buffer(ioaddr);
    databus = 'h58;
    @ (negedge clk);
    select_db_high_div_buffer(ioaddr);
    databus = 'h14; 
    repeat (1000) @ (posedge clk);
    while (~rx_q_empty) begin
        @ (negedge clk);
        read_spart_buffer(iorw_n);
        @ (posedge clk);
        // Compare the buffered data and the data we wrote
        buffer_front = buffer_data.pop_front();
        if (buffer_front == databus)
            $display("Succuesfully read data from the buffer, READ DATA = %h", databus);
        else
            $display("Read and write data mismatch, READ DATA = %h, WRITE DATA = %h", databus, buffer_front);
    end 
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
task automatic select_db_low_div_buffer (ref logic [1:0] ioaddr);
    ioaddr = 'b10;
endtask

// This task selects SB high division buffer
task automatic select_db_high_div_buffer (ref logic [1:0] ioaddr);
    ioaddr = 'b11;
endtask

endmodule
