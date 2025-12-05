`timescale 1ns/1ps

module Cartoon_Filter (
    input  logic       DE,
    input  logic       on_off,

    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,

    input  logic [3:0] r_right,
    input  logic [3:0] g_right,
    input  logic [3:0] b_right,

    input  logic [3:0] r_down,
    input  logic [3:0] g_down,
    input  logic [3:0] b_down,

    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);

    localparam logic [3:0] AUT_R = 15, AUT_G = 10, AUT_B = 5;
    localparam logic [8:0] EDGE_THR = 9'd4;

    logic [3:0] r_flat, g_flat, b_flat;

    always_comb begin
        r_flat = (r_in > 7) ? 4'd12 : 4'd4;
        g_flat = (g_in > 7) ? 4'd12 : 4'd4;
        b_flat = (b_in > 7) ? 4'd12 : 4'd4;
    end

    logic signed [8:0] diff_r, diff_g, diff_b;
    logic [8:0] abs_r, abs_g, abs_b;
    logic is_edge;

    always_comb begin
        diff_r = (r_in - r_right) + (r_in - r_down);
        diff_g = (g_in - g_right) + (g_in - g_down);
        diff_b = (b_in - b_right) + (b_in - b_down);

        abs_r = diff_r[8] ? (~diff_r + 1) : diff_r;
        abs_g = diff_g[8] ? (~diff_g + 1) : diff_g;
        abs_b = diff_b[8] ? (~diff_b + 1) : diff_b;

        is_edge = (abs_r >= EDGE_THR) ||
                  (abs_g >= EDGE_THR) ||
                  (abs_b >= EDGE_THR);
    end

    function automatic [3:0] clamp4(input signed [9:0] v);
        if (v < 0) clamp4 = 0;
        else if (v > 15) clamp4 = 15;
        else clamp4 = v[3:0];
    endfunction

    always_comb begin
        if (!DE) begin
            r_out=0; g_out=0; b_out=0;
        end
        else if (!on_off) begin
            r_out=r_in; g_out=g_in; b_out=b_in;
        end
        else if (is_edge) begin
            r_out=0; g_out=0; b_out=0;
        end
        else begin
            r_out = clamp4(r_flat + AUT_R);
            g_out = clamp4(g_flat + AUT_G);
            b_out = clamp4(b_flat + AUT_B);
        end
    end

endmodule










module PixelWindow3x3 (
    input  logic        clk,
    input  logic        reset,
    input  logic        DE,
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,

    output logic [16:0] rAddr,
    input  logic [15:0] rData,

    output logic [15:0] pix00, pix01, pix02,
    output logic [15:0] pix10, pix11, pix12,
    output logic [15:0] pix20, pix21, pix22
);
    typedef enum logic [3:0] {
        S00,S01,S02,
        S10,S11,S12,
        S20,S21,S22
    } state_t;

    state_t state, next;

    logic [16:0] base_addr;

    always_comb begin
        base_addr = y_pixel * 320 + x_pixel;
    end

    always_comb begin
        case (state)
            S00: rAddr = base_addr - 321;
            S01: rAddr = base_addr - 320;
            S02: rAddr = base_addr - 319;
            S10: rAddr = base_addr - 1;
            S11: rAddr = base_addr;
            S12: rAddr = base_addr + 1;
            S20: rAddr = base_addr + 319;
            S21: rAddr = base_addr + 320;
            S22: rAddr = base_addr + 321;
            default: rAddr = base_addr;
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pix00<=0; pix01<=0; pix02<=0;
            pix10<=0; pix11<=0; pix12<=0;
            pix20<=0; pix21<=0; pix22<=0;
            state <= S00;
        end else begin
            state <= next;
            case (state)
                S00: pix00 <= rData;
                S01: pix01 <= rData;
                S02: pix02 <= rData;

                S10: pix10 <= rData;
                S11: pix11 <= rData;
                S12: pix12 <= rData;

                S20: pix20 <= rData;
                S21: pix21 <= rData;
                S22: pix22 <= rData;
            endcase
        end
    end

    always_comb begin
        if (!DE) next = S00;
        else case (state)
            S00: next=S01; S01: next=S02; S02: next=S10;
            S10: next=S11; S11: next=S12; S12: next=S20;
            S20: next=S21; S21: next=S22; S22: next=S00;
            default: next=S00;
        endcase
    end

endmodule
