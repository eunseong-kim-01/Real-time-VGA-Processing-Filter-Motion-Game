`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/23 23:57:55
// Design Name: 
// Module Name: Mopology_Filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Mopology_Filter #(
    parameter IMG_WIDTH = 640,
    parameter ADDR_WIDTH = 10  // log2(640) ? 10
)(
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,   
    input logic [9:0] x_coor,
    input logic [9:0] y_coor,
    input logic DE,
    output logic [11:0] o_data  
);

    // Line buffers using inferred block RAM
    logic [0:0] erode_line1_ram [0:IMG_WIDTH-1];
    logic [0:0] erode_line2_ram [0:IMG_WIDTH-1];

    logic erode_read1, erode_read2;
    logic [0:0] erode_line1_pixel, erode_line2_pixel;

    // 3x3 windows
    logic erode_p11, erode_p12, erode_p13;
    logic erode_p21, erode_p22, erode_p23;
    logic erode_p31, erode_p32, erode_p33;

    logic [2:0] erode_valid_pipeline;
    logic [11:0] erode_o_data_internal;
    logic erode_oe_internal;

    logic [0:0] dilate_line1_ram [0:IMG_WIDTH-1];
    logic [0:0] dilate_line2_ram [0:IMG_WIDTH-1];
    logic [0:0] dilate_line1_pixel, dilate_line2_pixel;

    logic dilate_p11, dilate_p12, dilate_p13;
    logic dilate_p21, dilate_p22, dilate_p23;
    logic dilate_p31, dilate_p32, dilate_p33;

    logic [2:0] dilate_valid_pipeline;

    // === Erode ===
    always_ff @(posedge clk) begin
        if (reset) begin
            erode_valid_pipeline <= 3'b0;
        end else if (DE) begin
            // shift 2 lines: line2 <= line1, line1 <= new
            erode_line2_ram[x_coor] <= erode_line1_ram[x_coor];
            erode_line1_ram[x_coor] <= i_data[11]; // use MSB as binarized

            // read for 3x3 window
            erode_line2_pixel <= erode_line2_ram[x_coor];
            erode_line1_pixel <= erode_line1_ram[x_coor];

            erode_p13 <= erode_line2_pixel;
            erode_p12 <= erode_p13;
            erode_p11 <= erode_p12;

            erode_p23 <= erode_line1_pixel;
            erode_p22 <= erode_p23;
            erode_p21 <= erode_p22;

            erode_p33 <= i_data[11];
            erode_p32 <= erode_p33;
            erode_p31 <= erode_p32;

            erode_valid_pipeline <= {erode_valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)};
        end else begin
            erode_valid_pipeline <= {erode_valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            erode_o_data_internal <= 12'h000;
            erode_oe_internal <= 1'b0;
        end else if (erode_valid_pipeline[2]) begin
            erode_oe_internal <= 1'b1;
            if (&{erode_p11, erode_p12, erode_p13, erode_p21, erode_p22, erode_p23, erode_p31, erode_p32, erode_p33})
                erode_o_data_internal <= 12'hFFF;
            else
                erode_o_data_internal <= 12'h000;
        end else begin
            erode_oe_internal <= 1'b0;
            erode_o_data_internal <= 12'h000;
        end
    end

    // === Dilate ===
    always_ff @(posedge clk) begin
        if (reset) begin
            dilate_valid_pipeline <= 3'b0;
        end else if (erode_oe_internal) begin
            dilate_line2_ram[x_coor] <= dilate_line1_ram[x_coor];
            dilate_line1_ram[x_coor] <= erode_o_data_internal[11];

            dilate_line2_pixel <= dilate_line2_ram[x_coor];
            dilate_line1_pixel <= dilate_line1_ram[x_coor];

            dilate_p13 <= dilate_line2_pixel;
            dilate_p12 <= dilate_p13;
            dilate_p11 <= dilate_p12;

            dilate_p23 <= dilate_line1_pixel;
            dilate_p22 <= dilate_p23;
            dilate_p21 <= dilate_p22;

            dilate_p33 <= erode_o_data_internal[11];
            dilate_p32 <= dilate_p33;
            dilate_p31 <= dilate_p32;

            dilate_valid_pipeline <= {dilate_valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)};
        end else begin
            dilate_valid_pipeline <= {dilate_valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            o_data <= 12'h000;
        end else if (dilate_valid_pipeline[2]) begin
            if (|{dilate_p11, dilate_p12, dilate_p13, dilate_p21, dilate_p22, dilate_p23, dilate_p31, dilate_p32, dilate_p33})
                o_data <= 12'hFFF;
            else
                o_data <= 12'h000;
        end else begin
            o_data <= 12'h000;
        end
    end

endmodule

module Gray_filter(
    input logic [3:0] i_red,
    input logic [3:0] i_green,
    input logic [3:0] i_blue,
    output logic [3:0] o_red,
    output logic [3:0] o_green,
    output logic [3:0] o_blue
    );
    
    logic [11:0] gray;
    
    assign gray = 51 * i_red + 179 * i_green + 26 * i_blue;
    
     assign o_red = gray[11:8];
     assign o_green = gray[11:8];
     assign o_blue = gray[11:8];
    

endmodule

