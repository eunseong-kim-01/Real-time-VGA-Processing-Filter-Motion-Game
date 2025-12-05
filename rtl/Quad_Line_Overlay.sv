`timescale 1ns / 1ps

module Quad_Cross_Overlay #(
    parameter int H_RES   = 640,
    parameter int V_RES   = 480,
    parameter int LINE_TH = 2,          // 십자선 두께 (픽셀 수)

    // 십자선 색 (4bit RGB)
    parameter [3:0] R_LINE = 4'h0,
    parameter [3:0] G_LINE = 4'hF,
    parameter [3:0] B_LINE = 4'hF
) (
    input  logic       DE_in,
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);
    // 중앙 좌표 (4분할 경계)
    localparam int CENTER_X = H_RES / 2;  // ex) 640 → 320
    localparam int CENTER_Y = V_RES / 2;  // ex) 480 → 240

    logic is_vert_line;
    logic is_horz_line;
    logic is_cross;

    always_comb begin
        // 기본값: 원본 패스
        r_out  = r_in;
        g_out  = g_in;
        b_out  = b_in;

        // 활성 영역에서만 십자선 판단
        is_vert_line = (x_in >= CENTER_X - LINE_TH) && (x_in < CENTER_X + LINE_TH);
        is_horz_line = (y_in >= CENTER_Y - LINE_TH) && (y_in < CENTER_Y + LINE_TH);
        is_cross     = DE_in && (is_vert_line || is_horz_line);

        if (is_cross) begin
            r_out = R_LINE;
            g_out = G_LINE;
            b_out = B_LINE;
        end
    end

endmodule