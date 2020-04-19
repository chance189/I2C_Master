/***
 * Author: Chance Reimer
 * Date: 4/18/2020
 * Purpose: Top module to test I2C Master to read ADT7420 temperature data
 */
`timescale 1fs / 1fs
module top(
    //All outputs are for tying directly to pinout on board Nexys 4 DDR (see constraints file)
    input clk,          //100MHz input crystal
    input rst,          //reset is tied to a switch on the board (active low)
    
    //ADT7420 Interface
    inout scl,          //I2C SCL
    inout sda,          //I2C SDA
    input TMP_INT,      //over temperature and under temperature indicator, (Denotes active when temperature is greater than what is stored in THIGH register)
    input TMP_CT,       //Critical over-temperature indicator
    
    //7Seg Display
    output [7:0] anode, 
    output [7:0] _7LED
    );
    
localparam [6:0] I2C_ADDR = 7'h4B;
localparam [7:0] DEVICE_ID = 8'hCB;

//Taken from page 14 of ADT7420
// Bit 7: 1 for 16 bit, Bit 6:5, 00 Continuous conversion, Bit 4 Comparator or interrupt mode (doesn't matter) Bit 3 Polarity of INT (Doesn't matter), Bit 2 Polarity of CT, Bit 1:0 11, 4 faults
localparam [7:0] CONFIG_BITS = 8'b10000011;

//State machine
localparam [3:0] SETUP        = 4'd0,
                 VERIFY_ID    = 4'd1,
                 WRITE_CONFIG = 4'd2,
                 WRITE_REQ    = 4'd3,
                 WRITE_FINISH = 4'd4,
                 TEMP_DATA_AQ = 4'd5,
                 READ_REQ     = 4'd6,
                 AWAIT_DATA   = 4'd7,
                 INCR_DATA_AQ = 4'd8,
                 ERROR        = 4'd9;

//Internal registers
reg [3:0 ] state;
reg [3:0 ] next_state;
reg [7:0 ] data_read;
reg [15:0] temp_data;
reg        en_cntr;
reg [26:0] cntr;
reg [23:0] read_bytes;
reg        temp_data_read;

//For I2C Master
reg  [7:0]  slave_addr;
reg  [15:0] i_sub_addr;
reg         i_sub_len;
reg  [23:0] i_byte_len;
reg  [7:0]  i_data_write;
reg         request_transmit;
wire [7:0]  data_out;
wire        valid_out;
wire        req_data_chunk;
wire        busy;
wire        nack;

//For driving 7SEG display
reg [19:0] SSEG_data;

//State machine for setup and 1 second reads of Temperature
always@(posedge clk or negedge rst) begin
    //Set all regs to a known state
    if(!rst) begin
        //For I2C Driver Regs
        slave_addr <= {I2C_ADDR, 1'b1};     //Pretty much always do reads for this module
        {i_sub_addr, i_sub_len, i_byte_len} <= 0;
        {i_data_write, request_transmit} <= 0;
        
        //For internal regs
        state <= SETUP;
        next_state <= SETUP;
        {read_bytes, data_read, temp_data_read} <= 0;
        {cntr, en_cntr} <= 0;
        SSEG_data <= 0;
    end
    else begin
        cntr <= en_cntr ? cntr + 1 : 0;
        temp_data_read <= 1'b0;
        case(state)
            SETUP: begin
                slave_addr <= {I2C_ADDR, 1'b1};     //LSB denotes read
                i_sub_addr <= 16'h0B;               //Register address is 0x0B for Device ID
                i_sub_len <= 1'b0;                  //Denotes reg addr is 8 bit
                i_byte_len <= 23'd1;                //Denotes 1 bytes to read
                i_data_write <= 8'b0;               //Nothing to write, this is a read
                state <= READ_REQ;
                next_state <= VERIFY_ID;
                request_transmit <= 1'b1;
            end
            
            VERIFY_ID: begin
                if(data_read == DEVICE_ID) begin
                    state <= WRITE_CONFIG;
                end
                else begin
                    state <= ERROR;
                end
                SSEG_data <= {8'h1D, 4'b0, data_read};
            end
            
            WRITE_CONFIG: begin
                slave_addr <= {I2C_ADDR, 1'b0};     //LSB denotes write
                i_sub_addr <= 16'h03;               //Register address is 0x03 for Configuration register
                i_sub_len <= 1'b0;                  //Denotes reg addr is 8 bit
                i_byte_len <= 23'd1;                //Denotes 1 bytes to write
                i_data_write <= CONFIG_BITS;        //Write our premade configuration register for what we want
                request_transmit <= 1'b1;
                state <= WRITE_REQ;
                next_state <= WRITE_FINISH;
            end
            
            WRITE_REQ: begin
                if(busy) begin
                    state <= WRITE_FINISH;
                    request_transmit <= 1'b0;
                end
            end
            
            WRITE_FINISH: begin
                if(!busy) begin
                    state <= TEMP_DATA_AQ;
                    en_cntr <= 1'b1;
                end
            end
            
            TEMP_DATA_AQ: begin
                if(cntr == 100_000_000) begin //1 sec delay
                    en_cntr <= 1'b0;
                    slave_addr <= {I2C_ADDR, 1'b1};     //LSB denotes read
                    i_sub_addr <= 16'h00;               //Register address is 0x00 for MSB of temperature
                    i_sub_len <= 1'b0;                  //Denotes reg addr is 8 bit
                    i_byte_len <= 23'd2;                //Denotes 2 bytes to read
                    i_data_write <= 8'b0;               //Nothing to write, this is a read
                    state <= READ_REQ;
                    next_state <= INCR_DATA_AQ;
                    request_transmit <= 1'b1;
                    read_bytes <= 0;
                    SSEG_data <= temp_data[15] ? ((~temp_data) + 1) / 128 : temp_data/128;  //Note here want bitwise not(~), not logical not(!), since we want to take 2's complement
                end
            end
            
            READ_REQ: begin
                if(busy) begin
                    state <= AWAIT_DATA;
                    request_transmit <= 1'b0;
                end
            end
            
            AWAIT_DATA: begin
                if(valid_out) begin
                    state <= next_state;
                    data_read <= data_out;
                end
            end
            
            INCR_DATA_AQ: begin
                if(read_bytes == i_byte_len-1) begin
                    state <= TEMP_DATA_AQ;
                    temp_data_read <= 1'b1;
                    en_cntr <= 1'b1;
                end
                else begin
                    read_bytes <= read_bytes + 1;
                    state <= AWAIT_DATA;
                end
                temp_data[(1-read_bytes)*8 +: 8] <= data_read;
            end
            
            ERROR: begin
                SSEG_data <= 20'hE7707;   //Error without having to put in an R
            end
            
            default:
                state <= SETUP;
        endcase
        
        //Error checking
        if(busy & nack) begin
            state <= ERROR;
        end
    end
end

//Instantiate daughter modules 
i2c_master i_i2c_master(.i_clk(clk),                    //input clock to the module @100MHz (or whatever crystal you have on the board)
                        .reset_n(rst),                  //reset for creating a known start condition
                        .i_addr_w_rw(slave_addr),       //7 bit address, LSB is the read write bit, with 0 being write, 1 being read
                        .i_sub_addr(i_sub_addr),        //contains sub addr to send to slave, partition is decided on bit_sel
                        .i_sub_len(i_sub_len),          //denotes whether working with an 8 bit or 16 bit sub_addr, 0 is 8bit, 1 is 16 bit
                        .i_byte_len(i_byte_len),        //denotes whether a single or sequential read or write will be performed (denotes number of bytes to read or write)
                        .i_data_write(i_data_write),    //Data to write if performing write action
                        .req_trans(request_transmit),   //denotes when to start a new transaction
                  
                        /** For Reads **/
                        .data_out(data_out),
                        .valid_out(valid_out),
                  
                        /** I2C Lines **/
                        .scl_o(scl),                    //i2c clck line, output by this module, 400 kHz
                        .sda_o(sda),                    //i2c data line, set to 1'bz when not utilized (resistors will pull it high)
                  
                        /** Comms to Master Module **/
                        .req_data_chunk(req_data_chunk),//Request master to send new data chunk in i_data_write
                        .busy(busy),                    //denotes whether module is currently communicating with a slave
                        .nack(nack)
                        );  

SSEG i_SSEG(.clk(clk),
            .rst(rst),
            .data(SSEG_data), 
            .anode(anode), 
            ._7LED(_7LED)
            );
endmodule
