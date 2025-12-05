`timescale 1ns / 1ps
module OV7670_Mem_Controller (
    input  logic        pclk,
    input  logic        reset,
    // OV7670 Side
    input  logic        href,
    input  logic        vsync,
    input  logic [ 7:0] data,
    // Memory Side
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wData
);

    logic [17:0] pixelCounter;
    logic [15:0] pixelData;

    assign wData = pixelData;

    // data logic 
    always_ff @(posedge pclk) begin
        if (reset) begin
            pixelCounter <= 0;
            pixelData   <= 0;
            we          <= 1'b0;
            wAddr       <= 0;
        end else begin
            if (href) begin
                if (pixelCounter[0] == 1'b0) begin
                    pixelData[15:8] <= data;
                    we              <= 1'b0;
                end else begin
                    pixelData[7:0] <= data;
                    we             <= 1'b1;
                    wAddr          <= wAddr + 1;
                end
                pixelCounter <= pixelCounter + 1;
            end else if (vsync) begin
                pixelCounter <= 0;
                we          <= 1'b0;
                wAddr <= 0;
            end
        end
    end


endmodule
