/***
 * Author: Chance Reimer
 * Purpose: testbench verifying validity of i2c master module
 * Date: 4/11/2020
 * Note: For this project, target is 400kHz I2C communication to communicate with an ADT7420
 */
//`define DEBUG
`timescale 1fs/1fs
module i2c_test_bench();
//Slave address of ADT7420
localparam [6:0] I2C_ADDR = 7'h4B;

//wires/regs needed for basic operation
reg [7:0] slave_addr, i_data_write;
reg  [15:0] i_sub_addr;
reg clk, reset_n, i_sub_len;
reg request_transmit;
reg [23:0] i_byte_len;
wire [7:0] data_out;
wire valid_out;
wire scl;
wire sda;
wire req_data_chunk, busy, nack;

//Values for testing data
reg en_sda, test_sda, test_sda_prev;
reg start_ind, stop_ind;
reg [7:0] test_data_in, test_data_out;

//Declare debug regs
`ifdef DEBUG
wire [3:0]  state;
wire [3:0]  next_state;
wire        reg_sda_o;
wire [7:0]  addr;
wire        rw;
wire [15:0] sub_addr;
wire        sub_len;
wire [23:0] byte_len;
wire        en_scl;
wire        byte_sent;
wire [23:0] num_byte_sent;
wire [2:0]  cntr;
wire [7:0]  byte_sr;
wire        read_sub_addr_sent_flag;
wire [7:0]  data_to_write;
wire [7:0]  data_in_sr;

//For generation of 400KHz clock
wire clk_i2c;
wire [15:0] clk_i2c_cntr;

//For taking a sample of the scl and sda
wire [1:0] sda_curr;       //So this one is asynchronous especially with replies from the slave, must have synchronization chain of 2
wire       sda_prev;
wire scl_prev, scl_curr;   //master will always drive this line, so it doesn't matter

wire ack_in_prog;          //For sending acks during read
wire ack_nack;
wire en_end_indicator;

wire grab_next_data, scl_is_high, scl_is_low;
`endif

//Here do 100MHz clock
initial begin
    clk = 0;
    forever #(5000000) clk = !clk;  //100MHz clock
end

assign sda = en_sda ? test_sda : 1'bz;

integer i;
//run test here
initial begin
    /************** Setup of test *****************/
    en_sda = 0;
    reset_n = 0;
    request_transmit = 1'b0;
    test_data_in = 0;
    test_data_out = 8'hBE;
    #500;
    reset_n = 1;
    #10000;
    
    /****** 8 bit Sub addr, and 2 byte write ******/
    $display("******** Write 2 Bytes Test: ********");
    slave_addr = {I2C_ADDR, 1'b0};
    i_data_write = 8'hFE;
    i_sub_addr = 8'h2E;
    i_sub_len = 1'b0;
    i_byte_len = 23'd2;
    @(posedge clk);
    request_transmit <= 1'b1;
    
    //Now await a start indication
    @(posedge busy);
    $display("Requisition Granted!");
    request_transmit = 1'b0;
    
    @(posedge start_ind);
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("SLAVE ADDR: %b", test_data_in);
    $display("Desired action: %s", test_data_in[0] ? "READ" : "WRITE");
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab sub addr
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Sub Addr MSB: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Grab Byte 1 for write
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Data Written, Byte 1: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    //This will be found between the two negedges
    @(posedge req_data_chunk);
    i_data_write <= 8'h07;
    
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab byte 2
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Data Written Byte 2: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    @(posedge stop_ind);
    $display("%t, STOP INDICATION! Finished Write of 2 Bytes", $time);
    @(negedge busy);
    $display("Let go of bus");
    
    /****** 8 bit Sub addr, and 2 byte read ******/
    $display("******** Read_2 Bytes Test: ********");
    //Do read test of 16bit address
    slave_addr = {I2C_ADDR, 1'b1};
    i_data_write = 8'hFE;
    i_sub_addr = 8'h2E;
    i_sub_len = 1'b0;
    i_byte_len = 23'd2;
    
    //Await for clock for requesting new data to transmit
     @(posedge clk);
    request_transmit <= 1'b1;
    
    //Now await a start indication
    @(posedge busy);
    $display("Requisition Granted!");
    request_transmit = 1'b0;
    
    @(posedge start_ind);
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("SLAVE ADDR: %b", test_data_in);
    $display("Desired action: %s", test_data_in[0] ? "READ" : "WRITE");
    
    //Reply Ack
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab sub addr
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Sub Addr MSB: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    @(posedge start_ind);
    $display("REPEAT START RECEIVED!");
    
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("SLAVE ADDR: %b", test_data_in);
    $display("Desired action: %s", test_data_in[0] ? "READ" : "WRITE");
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    
    //Take control of SDA and ensure master can read data
    for(i = 7; i >= 0; i = i - 1) begin
        @(negedge scl);
        #1;
        test_sda = test_data_out[i];
    end
    
    @(negedge scl);
    en_sda = 0;
    
    @(posedge scl);
    $display("RECEIVED: %s", sda ? "NACK" : "ACK");
    test_data_out = 8'hEF;
    @(negedge scl);
    en_sda = 1;
    test_sda = test_data_out[7];
    
    //Take control of SDA and ensure master can read data
    for(i = 6; i >= 0; i = i - 1) begin
        @(negedge scl);
        #1;
        test_sda = test_data_out[i];
    end
    
    @(negedge scl);
    en_sda = 0;
    
    @(posedge scl);
    $display("RECEIVED: %s", sda ? "NACK" : "ACK");
    
    @(posedge stop_ind);
    $display("%t, STOP INDICATION! Finished read of 2 bytes", $time);
    
    @(negedge busy);
    $display("Let go of bus");
    
    /****** 16 bit Sub addr, and 4 byte write ******/
    $display("******** Write 3 Bytes Test, 16 bit sub addr: ********");
    slave_addr = {7'h3A, 1'b0};
    i_data_write = 8'hDE;
    i_sub_addr = 16'hBEEF;
    i_sub_len = 1'b1;               //Denote 16 bit sub addr
    i_byte_len = 23'd4;             //Denote 4 byte write
    @(posedge clk);
    request_transmit <= 1'b1;
    
    //Now await a start indication
    @(posedge busy);
    $display("Requisition Granted!");
    request_transmit = 1'b0;
    
    @(posedge start_ind);
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("SLAVE ADDR: %b", test_data_in);
    $display("Desired action: %s", test_data_in[0] ? "READ" : "WRITE");
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab sub addr MSB
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Sub Addr MSB: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab sub addr LSB
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Sub Addr LSB: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Grab Byte 1 for write
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Data Written, Byte 1: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    //This will be found between the two negedges
    @(posedge req_data_chunk);
    i_data_write <= 8'hAD;
    
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab byte 2
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Data Written Byte 2: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    //This will be found between the two negedges
    @(posedge req_data_chunk);
    i_data_write <= 8'hBE;
    
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab byte 3
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Data Written Byte 3: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    //This will be found between the two negedges
    @(posedge req_data_chunk);
    i_data_write <= 8'hEF;
    
    @(negedge scl);
    #10;
    en_sda = 0;
    
    //Now grab byte 4
    for(i = 7; i >= 0; i = i - 1) begin
        @(posedge scl);
        #1;
        test_data_in[i] = sda;
    end
    $display("Data Written Byte 4: %h", test_data_in);
    
    @(negedge scl);
    #10;
    en_sda = 1;
    test_sda = 1'b0;
    @(negedge scl);
    #10;
    en_sda = 0;
    
    @(posedge stop_ind);
    $display("%t, STOP INDICATION! Finished Write of 2 Bytes", $time);
    @(negedge busy);
    $display("Let go of bus");
    
    $display("******** Test Finished ********");
end

//Assigning for sda previous in testbench, and determining start and stop signals
always@(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        {start_ind, stop_ind, test_sda_prev} <= 0;
    end
    else begin
        test_sda_prev <= sda;
        start_ind <= test_sda_prev & !sda & scl;  //If scl is high and there was a change in sda (high to low) then start
        stop_ind <= !test_sda_prev & sda & scl;   //reverse of above
    end
end

i2c_master DUT(.i_clk(clk),                     //input clock to the module @100MHz (or whatever crystal you have on the board)
               .reset_n(reset_n),               //reset for creating a known start condition
               .i_addr_w_rw(slave_addr),        //7 bit address, LSB is the read write bit, with 0 being write, 1 being read
               .i_sub_addr(i_sub_addr),         //contains sub addr to send to slave, partition is decided on bit_sel
               .i_sub_len(i_sub_len),           //denotes whether working with an 8 bit or 16 bit sub_addr, 0 is 8bit, 1 is 16 bit
               .i_byte_len(i_byte_len),         //denotes whether a single or sequential read or write will be performed (denotes number of bytes to read or write)
               .i_data_write(i_data_write),     //Data to write if performing write action
               .req_trans(request_transmit),    //denotes when to start a new transaction
                  
                  /** For Reads **/
               .data_out(data_out),
               .valid_out(valid_out),
                  
                  /** I2C Lines **/
               .scl_o(scl),             //i2c clck line, output by this module, 400 kHz
               .sda_o(sda),             //i2c data line, set to 1'bz when not utilized (resistors will pull it high)
                  
                  /** Comms to Master Module **/
               .req_data_chunk(req_data_chunk),  //Request master to request new data chunk in i_data_write
               .busy(busy),                      //denotes whether module is currently communicating with a slave
               .nack(nack)                       //denotes whether module is encountering a nack from slave (only activates when master is attempting to contact device)
                  
              `ifdef DEBUG
              ,
              .state(state),
              .next_state(next_state),
              .reg_sda_o(reg_sda_o),
              .addr(addr),
              .rw(rw),
              .sub_addr(sub_addr),
              .sub_len(sub_len),
              .byte_len(byte_len),
              .en_scl(en_scl),
              .byte_sent(byte_sent),
              .num_byte_sent(num_byte_sent),
              .cntr(cntr),
              .byte_sr(byte_sr),
              .read_sub_addr_sent_flag(read_sub_addr_sent_flag),
              .data_to_write(data_to_write),
              .data_in_sr(data_in_sr),
                  
              //400KHz clock generation
              .clk_i2c(clk_i2c),
              .clk_i2c_cntr(clk_i2c_cntr),
                  
              //sampling sda and scl
              .sda_prev(sda_prev),
              .sda_curr(sda_curr),
              .scl_prev(scl_prev),
              .scl_curr(scl_curr),
              .ack_in_prog(ack_in_prog),
              .ack_nack(ack_nack),
              .en_end_indicator(en_end_indicator),
              .grab_next_data(grab_next_data),
              .scl_is_high(scl_is_high),
              .scl_is_low(scl_is_low)
              `endif
              );

endmodule