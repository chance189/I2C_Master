# I2C_Master -- Verilog Implementation

### Introduction

I2C stands for Inter-Integrated Circuit, which consists of a multi-master, multiple slave bus. Each slave has a unique ID, allowing the master to select one and read or write information to it.
I2C is open drain, meaning that the bus is pulled up to VCC (the supply voltage) via pull up resistors, so it is active high. The bus consists of two lines, the scl, or clock, and sda or data.
The master module will take control of the bus via a start indication, write a slave address, a sub address, and then read or write a given number of bytes.
For more in depth information of I2C, please lookup Texas Instruments "Understanding the I2C Bus" Application Report, SLVA704, written on June 2015.

### Getting Started/How to use

The current verilog module is targeted to meet the minimum requirements of the ADT7420 Temperature sensor. The specifications for timing requirements can be found in this IC's specification sheet.
For a bus with multiple slaves, find the slowest item on the bus, and ensure that the minimum setup and hold times will be met by the module. These are defined in a localparam at the beginning of the file.
Additionally, this module is targeted for scl of 400KHz, if your target cannot reach this speed, you must modify the clock generation of the module. If the subsequent divisor is a fraction, look up a fractional clock divider.

### Simulation Results

The simulation can be run using ModelSim from Altera, or using Xilinx's Vivado testbench. The testbench included in this file runs through multiple byte reads, and writes, included slave addresses that are up to 16 bits.
Make modification as necessary for your use case.

To see all internal registers, uncomment the "\`define DEBUG" at the top of both the test bench and the other file.

### Verification on Nexys 4 DDR

In the folder \Nexys_4_Test a few files are included: top.v, and SSEG.v, and nexys.xdc. The files are utilized to run on the Nexys 4, communicating with the ADT7420 on the board, getting Celcius temperature readings every
second, and display them on the seven segment displays. Note that the output temperature is in Celcius, and is rounded to nearest integer. To get decimal, simply shift to the right however decimal precision you want, and select a fixed point.
The output temperature is displayed in hexadecimal, therefore 1A would be equal to 26C, or 78.8F. 

### Author
* Chance Reimer