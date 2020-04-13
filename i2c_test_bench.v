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
wire [7:0] slave_addr = 8'h4B;

i2c_master DUT(input				i_clk,				//input clock to the module @100MHz (or whatever crystal you have on the board)
				  input				reset_n,			//reset for creating a known start condition
				  input		 [7:0]  i_addr_w_rw,		//7 bit address, LSB is the read write bit, with 0 being write, 1 being read
				  input		 [15:0] i_sub_addr,			//contains sub addr to send to slave, partition is decided on bit_sel
				  input				i_sub_len,			//denotes whether working with an 8 bit or 16 bit sub_addr, 0 is 8bit, 1 is 16 bit
				  input		 [23:0] i_byte_len,			//denotes whether a single or sequential read or write will be performed (denotes number of bytes to read or write)
                  input      [7:0]  i_data_write,       //Data to write if performing write action
                  input             req_trans,          //denotes when to start a new transaction
                  
                  /** For Reads **/
                  output reg [7:0]  data_out,
                  output reg        valid_out,
                  
                  /** I2C Lines **/
				  inout      		scl_o,			    //i2c clck line, output by this module, 400 kHz
				  inout				sda_o,				//i2c data line, set to 1'bz when not utilized (resistors will pull it high)
                  
                  /** Comms to Master Module **/
                  output reg        req_data_chunk      //Request master to request new data chunk in i_data_write
				  output reg		busy,				//denotes whether module is currently communicating with a slave
                  output reg        nack                //denotes whether module is encountering a nack from slave (only activates when master is attempting to contact device)
				  
				  `ifdef DEBUG
				  ,
				  output reg [3:0]  state,
                  output reg [3:0]  next_state,
                  output reg        reg_sda_o,
                  output reg [7:0]  addr,
                  output reg        rw,
                  output reg [15:0] sub_addr,
                  output reg        sub_len,
                  output reg [23:0] byte_len,
                  output reg        en_scl,
                  output reg        byte_sent,
                  output reg [23:0] num_byte_sent,
                  output reg [2:0]  cntr,
                  output reg [7:0]  byte_sr,
                  output reg        read_sub_addr_sent_flag,
                  output reg [7:0]  data_to_write,
                  output reg [7:0]  data_in_sr,
                  
                  //400KHz clock generation
                  output reg        clk_i2c,
                  output reg [15:0] clk_i2c_cntr,
                  
                  //sampling sda and scl
                  output reg [1:0]  sda_prev,
                  output reg [1:0]  sda_curr,
                  output reg        scl_prev,
                  output reg        scl_curr,
                  output reg        ack_in_prog,
                  output reg        ack_nack,
                  output reg        en_end_indicator,
                  output reg        grab_next_data
				  `endif
				  );

endmodule