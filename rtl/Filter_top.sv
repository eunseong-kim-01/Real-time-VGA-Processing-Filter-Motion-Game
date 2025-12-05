`timescale 1ns / 1ps

module Filter_top(
    // globsig
    input logic sys_clk,
    input logic reset,
    // VGA Data
    input logic [3:0] r_raw,
    input logic [3:0] g_raw,
    input logic [3:0] b_raw,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    // filter RGB
    // Gray, monopoloy
    output logic [3:0] r_gray,
    output logic [3:0] g_gray,
    output logic [3:0] b_gray,
    output logic [11:0] filtered_data,
    // gausian, sobel
    output logic [3:0] r_blur,
    output logic [3:0] g_blur,
    output logic [3:0] b_blur,
    output logic [3:0] r_edge,
    output logic [3:0] g_edge,
    output logic [3:0] b_edge,
    // retro fillter
    output logic [3:0] r_retro,
    output logic [3:0] g_retro,
    output logic [3:0] b_retro,
    // cartoon filter
    input logic on_off,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,

    input  logic [3:0] r_right,
    input  logic [3:0] g_right,
    input  logic [3:0] b_right,

    input  logic [3:0] r_down,
    input  logic [3:0] g_down,
    input  logic [3:0] b_down,
    output logic [3:0] r_cart,
    output logic [3:0] g_cart,
    output logic [3:0] b_cart
    // 
    );
    logic de_g_2_s;

    Gray_filter U_GRAY (
        .i_red  (r_raw),   
        .i_green(g_raw),
        .i_blue (b_raw),
        .o_red  (r_gray),
        .o_green(g_gray),
        .o_blue (b_gray)
    );

    Mopology_Filter U_MOPOLOGY_FILTER (
        .clk(sys_clk),
        .reset(reset),
        .i_data({r_gray, g_gray, b_gray}),
        .x_coor(x_pixel),
        .y_coor(y_pixel),
        .DE(DE),
        .o_data(filtered_data)
    );


     Gaussian_Filter #(
        .H_RES(640)
    ) U_Gaussian_Filter (
        .clk(sys_clk),
        .reset(reset),
        .de_in(DE),
        .x_in(x_pixel),
        .y_in(y_pixel),
        .r_in(r_raw),
        .g_in(g_raw),
        .b_in(b_raw),
        .de_out(de_g_2_s),
        .r_out(r_blur),
        .g_out(g_blur),
        .b_out(b_blur)
    );

    Sobel_edge #(
        .H_RES(640)
    ) U_Sobel_Edge (
        .clk(sys_clk),
        .reset(reset),
        .de_in(de_g_2_s),
        .x_in(x_pixel),
        .y_in(y_pixel),
        .r_in(r_blur),
        .g_in(g_blur),
        .b_in(b_blur),
        .de_out(),
        .r_out(r_edge),
        .g_out(g_edge),
        .b_out(b_edge)
    );


    RetroFilter U_RetroFilter(
     .r_in(r_raw),
     .g_in(g_raw),
     .b_in(b_raw),
     .r_out(r_retro),
     .g_out(g_retro),
     .b_out(b_retro)
);

    Cartoon_Filter U_CART_FILTER(
    .DE(DE),
    .on_off(on_off),
    .r_in(r_in),
    .g_in(g_in),
    .b_in(b_in),
    .r_right(r_right),
    .g_right(g_right),
    .b_right(b_right),
    .r_down(r_down),
    .g_down(g_down),
    .b_down(b_down),
    .r_out(r_cart),
    .g_out(g_cart),
    .b_out(b_cart)
);



endmodule
