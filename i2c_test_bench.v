/***
 * Author: Chance Reimer
 * Purpose: testbench verifying validity of i2c master module
 * Date: 4/11/2020
 * Note: For this project, target is 400kHz I2C communication to communicate with an ADT7420
 */

module i2c_test_bench();

//Slave address of ADT7420
wire [7:0] slave_addr = 8'h4B;

endmodule