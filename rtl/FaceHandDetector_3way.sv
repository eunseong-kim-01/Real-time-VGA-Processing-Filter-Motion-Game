`timescale 1ns/1ps
module ColorDetector_4way(
    input  logic clk,
    input  logic vsync,
    input  logic DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,

    output logic pass_LT,
    output logic pass_RT,
    output logic pass_LB,
    output logic pass_RB
);

    //------------------------------------------------------------
    // vsync rising edge detect → frame start
    //------------------------------------------------------------
    logic vs_d, vs_rise;
    always_ff @(posedge clk) begin
        vs_d    <= vsync;
        vs_rise <= vsync & ~vs_d;
    end

    //------------------------------------------------------------
    // Color Detect (HSV-lite)
    //------------------------------------------------------------
    logic [3:0] maxC, minC, diff;

    assign maxC = (r_in >= g_in && r_in >= b_in) ? r_in :
                  (g_in >= b_in) ? g_in : b_in;

    assign minC = (r_in <= g_in && r_in <= b_in) ? r_in :
                  (g_in <= b_in) ? g_in : b_in;

    assign diff = maxC - minC;

    logic is_gray;
    assign is_gray = (diff < 2);

    logic is_black;
    assign is_black = (maxC <= 2);

    logic is_red;
    assign is_red = (!is_gray && maxC == r_in);

    logic is_green;
    assign is_green = (!is_gray && maxC == g_in);

    logic is_blue;
    assign is_blue = (!is_gray && maxC == b_in);

    //------------------------------------------------------------
    // Region Definition (20×20)
    //------------------------------------------------------------
    logic in_LT, in_RT, in_LB, in_RB;

    assign in_LT = (x_pixel >= 170 && x_pixel < 190 &&
                    y_pixel >= 125 && y_pixel < 145);

    assign in_LB = (x_pixel >= 170 && x_pixel < 190 &&
                    y_pixel >= 335 && y_pixel < 355);

    assign in_RT = (x_pixel >= 450 && x_pixel < 470 &&
                    y_pixel >= 125 && y_pixel < 145);

    assign in_RB = (x_pixel >= 450 && x_pixel < 470 &&
                    y_pixel >= 335 && y_pixel < 355);

    //------------------------------------------------------------
    // PASS Set Logic
    //------------------------------------------------------------
    always_ff @(posedge clk) begin
        if(vs_rise) begin
            pass_LT <= 0;
            pass_RT <= 0;
            pass_LB <= 0;
            pass_RB <= 0;
        end
        else begin
            if(DE && is_blue  && in_LT) pass_LT <= 1;
            if(DE && is_black && in_LB) pass_LB <= 1;
            if(DE && is_red   && in_RT) pass_RT <= 1;
            if(DE && is_green && in_RB) pass_RB <= 1;
        end
    end

endmodule




































