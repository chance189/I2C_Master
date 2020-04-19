`timescale 1fs/1fs

/*
* Chance Reimer
* Ver 2 
* Date: 4/18/2020
*/

module SSEG(input clk,
            input rst,
            input [19:0] data,    //have 5 hex digits, 
            output reg [7:0] anode, 
            output reg [7:0] _7LED
            );

//LUT for the display
wire [7:0] anodeSelect [0:15]; //here is our select for our Anode use codes 0-9 for our LUT
assign anodeSelect[0]  = 8'b00000010; //0 //ABCDEFGDP is pinout, active low
assign anodeSelect[1]  = 8'b10011110; //1
assign anodeSelect[2]  = 8'b00100100; //2
assign anodeSelect[3]  = 8'b00001100; //3
assign anodeSelect[4]  = 8'b10011000; //4
assign anodeSelect[5]  = 8'b01001000; //5 
assign anodeSelect[6]  = 8'b01000000; //6
assign anodeSelect[7]  = 8'b00011110; //7
assign anodeSelect[8]  = 8'b00000000; //8
assign anodeSelect[9]  = 8'b00001000; //9
assign anodeSelect[10] = 8'b00010000; //A
assign anodeSelect[11] = 8'b11000000; //b
assign anodeSelect[12] = 8'b01100010; //C
assign anodeSelect[13] = 8'b10000100; //d
assign anodeSelect[14] = 8'b01100000; //E
assign anodeSelect[15] = 8'b01110000; //F

reg [19:0] refresh; //sets enable for refresh rate
reg [3:0] select; //determines what value will be sent out to chosen 7 seg
reg [3:0] hex0;
reg [3:0] hex1;
reg [3:0] hex2;
reg [3:0] hex3;
reg [3:0] hex4;

wire [3:0] enable; //tells when to switch to next anode

//this always block gives the refresh rate for the 7seg display
always@(posedge clk or negedge rst)
begin
    if(!rst)
        refresh <= 0;
    else
        refresh <= refresh+1;
end

//this enable value is actually what is checked to move to the next 7seg
assign enable = refresh[19:16];

//this will always select the proper output based on the toggle
always@(posedge clk)
begin 
        hex0 <=  data%16;
        hex1 <= (data >> 4)  % 16;
        hex2 <= (data >> 8)  % 16;
        hex3 <= (data >> 12) % 16;
        hex4 <= (data >> 16) % 16;
end

always@(*)
begin
    case(enable)
             4'b0000: begin
                select = hex4;
                anode = 8'b1110_1111; //this is for the hundreds
            end
            4'b0010: begin
                select = hex3;
                anode = 8'b1111_0111; //this is for the tens
            end
            4'b0100: begin
                select = hex2;
                anode = 8'b1111_1011; //This is for the ones
            end
            4'b0110: begin
                select = hex1;
                anode = 8'b1111_1101;
            end
            4'b0111: begin
                select = hex0;
                anode = 8'b1111_1110;
            end
            
            default: begin
                select = hex0;
                anode = 8'b1111_1110;
            end
    endcase
end

//here we assign our LUT to the _7LED
always@(*)
begin
    case(select)
        4'b0000: _7LED = anodeSelect[0];  // 0     
        4'b0001: _7LED = anodeSelect[1];  // 1 
        4'b0010: _7LED = anodeSelect[2];  // 2 
        4'b0011: _7LED = anodeSelect[3];  // 3 
        4'b0100: _7LED = anodeSelect[4];  // 4 
        4'b0101: _7LED = anodeSelect[5];  // 5
        4'b0110: _7LED = anodeSelect[6];  // 6 
        4'b0111: _7LED = anodeSelect[7];  // 7 
        4'b1000: _7LED = anodeSelect[8];  // 8    
        4'b1001: _7LED = anodeSelect[9];  // 9 
        4'b1010: _7LED = anodeSelect[10]; // A
        4'b1011: _7LED = anodeSelect[11]; // B
        4'b1100: _7LED = anodeSelect[12]; // C
        4'b1101: _7LED = anodeSelect[13]; // D
        4'b1110: _7LED = anodeSelect[14]; // E
        4'b1111: _7LED = anodeSelect[15]; // F
        default: _7LED = anodeSelect[0];  // 0		
    endcase
end
endmodule
