`timescale 1ns / 1ps

module ov7670_I2C_Top (
    input  logic clk,
    input  logic reset,
    input  logic start,
    output logic busy,
    output logic done,
    output logic scl,
    inout  tri   sda

);

    logic I2C_EN;
    logic I2C_START;
    logic I2C_STOP;
    logic [7:0] tx_data;
    logic tx_ready;
    logic [6:0] rom_addr;
    logic [15:0] rom_data;



    I2C_Master U_I2C_Master (
        .*,
        .rd_ack (),
        .tx_done(),
        .rx_data(),
        .rx_done()
    );

    ov7670_SCCB_Controller U_SCCB_CTRL (.*);
    Camera_Rom U_Camera_Rom (.*);
endmodule
