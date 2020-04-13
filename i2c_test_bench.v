/***
 * Author: Chance Reimer
 * Purpose: testbench verifying validity of i2c master module
 * Date: 4/11/2020
 * Note: For this project, target is 400kHz I2C communication to communicate with an ADT7420
 */
`define DEBUG
`timescale 1fs/1fs
module i2c_test_bench();
//Slave address of ADT7420
localparam [6:0] I2C_ADDR = 7'4B;

//wires/regs needed for basic operation
reg [7:0] slave_addr, i_data_write;
reg  [15:0] i_sub_addr;
reg clk, reset_n, i_sub_len;
reg request_transmit;
reg [23:0] i_byte_len;
wire [7:0] data_out;
wire valid_out;
inout scl, sda;
wire req_data_chunk, busy, nack;

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
wire [1:0] sda_curr;    //So this one is asynchronous especially with replies from the slave, must have synchronization chain of 2
wire       sda_prev;
wire scl_prev, sda_curr;          //master will always drive this line, so it doesn't matter

wire ack_in_prog;      //For sending acks during read
wire ack_nack;
wire en_end_indicator;

wire grab_next_data;
`endif

//Here do 100MHz clock
initial begin
    clk = 0;
    forever #(5000000) clk = !clk;  //100MHz clock
end

//run test here
initial begin
    reset_n = 0;
    #500;
    reset_n = 1;
end

i2c_master DUT(.i_clk(clk),				//input clock to the module @100MHz (or whatever crystal you have on the board)
			   .reset_n(reset_n),			//reset for creating a known start condition
			   .i_addr_w_rw(slave_addr),		//7 bit address, LSB is the read write bit, with 0 being write, 1 being read
			   .i_sub_addr(i_sub_addr),			//contains sub addr to send to slave, partition is decided on bit_sel
               .i_sub_len(i_sub_len),			//denotes whether working with an 8 bit or 16 bit sub_addr, 0 is 8bit, 1 is 16 bit
			   .i_byte_len(i_byte_len),			//denotes whether a single or sequential read or write will be performed (denotes number of bytes to read or write)
               .i_data_write(i_data_write),       //Data to write if performing write action
               .req_trans(request_transmit),          //denotes when to start a new transaction
                  
                  /** For Reads **/
               .data_out(data_out),
               .valid_out(valid_out),
                  
                  /** I2C Lines **/
               .scl_o(scl),			    //i2c clck line, output by this module, 400 kHz
               .sda_o(sda),				//i2c data line, set to 1'bz when not utilized (resistors will pull it high)
                  
                  /** Comms to Master Module **/
               .req_data_chunk(req_data_chunk)      //Request master to request new data chunk in i_data_write
               .busy(busy),				//denotes whether module is currently communicating with a slave
               .nack(nack)                //denotes whether module is encountering a nack from slave (only activates when master is attempting to contact device)
				  
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
              .grab_next_data(grab_next_data)
              `endif
              );

endmodule