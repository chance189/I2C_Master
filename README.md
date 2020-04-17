# I2C_Master -- Verilog Implementation

### Introduction

I2C stands for Inter-Integrated Circuit, which consists of a multi-master, multiple slave bus. Each slave has a unique ID, allowing the master to select one and read or write information to it.
I2C is open drain, meaning that the bus is pulled up to VCC (the supply voltage) via pull up resistors, so it is active high. The bus consists of two lines, the scl, or clock, and sda or data.
The master module will take control of the bus via a start indication, write a slave address, a sub address, and then read or write a given number of bytes.
For more in depth information of I2C, please lookup Texas Instruments "Understanding the I2C Bus" Application Report, SLVA704, written on June 2015.

### Getting Started/How to use

### Simulation Results

### Testing on Nexys 4 DDR

### Author
* Chance Reimer