`timescale 1ns / 1ps
// Gaussian 3x3 필터 (RGB444, H_RES=640 기준)
module Gaussian_Filter #(
    parameter int H_RES = 640
) (
    input  logic       clk,
    input  logic       reset,

    // 입력 스트림
    input  logic       de_in,
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,

    // 출력 스트림 (동일 타이밍, 픽셀만 Blur)
    output logic       de_out,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);
    // -----------------------------
    // 1) Line buffer (이전/현재 라인)
    // -----------------------------
    logic [3:0] line_r0[0:H_RES-1];  // y-1
    logic [3:0] line_g0[0:H_RES-1];
    logic [3:0] line_b0[0:H_RES-1];

    logic [3:0] line_r1[0:H_RES-1];  // y
    logic [3:0] line_g1[0:H_RES-1];
    logic [3:0] line_b1[0:H_RES-1];

    // 3x3 윈도우 레지스터
    logic [3:0] w_r[0:2][0:2];
    logic [3:0] w_g[0:2][0:2];
    logic [3:0] w_b[0:2][0:2];

    // DE/x/y 파이프라인 및 line_start
    logic       img_de;
    logic       img_de_d;
    logic [9:0] x_d, y_d;

    assign img_de = de_in
              && (x_in >= 2)
              && (y_in >= 2)
              && (x_in < H_RES)
              && (y_in < 480);
    wire line_start = de_in && (x_in == 10'd0);  // 활성 라인 시작

    // -----------------------------
    // 2) line buffer + 3x3 window 업데이트
    // -----------------------------
    integer i, j;
    always_ff @(posedge clk) begin
        if (reset) begin
            // 굳이 배열 전체 초기화까지는 필요 없지만
            // 세로 라인 아티팩트 방지를 위해 window만 0으로 클리어
            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3; j++) begin
                    w_r[i][j] <= '0;
                    w_g[i][j] <= '0;
                    w_b[i][j] <= '0;
                end
            end
        end else if (de_in) begin
            // (1) line buffer: 직전 라인은 line_0, 현재 라인은 line_1 에 저장
            line_r0[x_in] <= line_r1[x_in];
            line_g0[x_in] <= line_g1[x_in];
            line_b0[x_in] <= line_b1[x_in];

            line_r1[x_in] <= r_in;
            line_g1[x_in] <= g_in;
            line_b1[x_in] <= b_in;

            if (line_start) begin
                // 새 라인 시작: 3x3 윈도우를 0으로 초기화
                // (초기 몇 픽셀은 원본 통과로 처리)
                for (i = 0; i < 3; i++) begin
                    for (j = 0; j < 3; j++) begin
                        w_r[i][j] <= '0;
                        w_g[i][j] <= '0;
                        w_b[i][j] <= '0;
                    end
                end
            end else begin
                // (2) 3x3 window: 왼쪽으로 쉬프트 후 새 값 채움
                // 윗줄: line_0
                w_r[0][0] <= w_r[0][1];
                w_r[0][1] <= w_r[0][2];
                w_r[0][2] <= line_r0[x_in];
                w_g[0][0] <= w_g[0][1];
                w_g[0][1] <= w_g[0][2];
                w_g[0][2] <= line_g0[x_in];
                w_b[0][0] <= w_b[0][1];
                w_b[0][1] <= w_b[0][2];
                w_b[0][2] <= line_b0[x_in];

                // 중간줄: line_1
                w_r[1][0] <= w_r[1][1];
                w_r[1][1] <= w_r[1][2];
                w_r[1][2] <= line_r1[x_in];
                w_g[1][0] <= w_g[1][1];
                w_g[1][1] <= w_g[1][2];
                w_g[1][2] <= line_g1[x_in];
                w_b[1][0] <= w_b[1][1];
                w_b[1][1] <= w_b[1][2];
                w_b[1][2] <= line_b1[x_in];

                // 아랫줄: 현재 입력
                w_r[2][0] <= w_r[2][1];
                w_r[2][1] <= w_r[2][2];
                w_r[2][2] <= r_in;
                w_g[2][0] <= w_g[2][1];
                w_g[2][1] <= w_g[2][2];
                w_g[2][2] <= g_in;
                w_b[2][0] <= w_b[2][1];
                w_b[2][1] <= w_b[2][2];
                w_b[2][2] <= b_in;
            end
        end
    end

    // x/y/de 1cycle pipeline (window와 정렬용)
    always_ff @(posedge clk) begin
        if (reset) begin
            img_de_d <= 1'b0;
            x_d      <= '0;
            y_d      <= '0;
        end else begin
            img_de_d <= img_de;
            if (de_in) begin
                x_d <= x_in;
                y_d <= y_in;
            end
        end
    end

    // -----------------------------
    // 3) 가우시안 커널 연산 (1 2 1; 2 4 2; 1 2 1)/16
    // -----------------------------
    function automatic logic [3:0] gauss_1ch(input logic [3:0] W[0:2][0:2]);
        logic [11:0] sum;
        begin
            sum = (W[0][0] + (W[0][1] << 1) + W[0][2]
                 + (W[1][0] << 1) + (W[1][1] << 2) + (W[1][2] << 1)
                 + W[2][0] + (W[2][1] << 1) + W[2][2]);
            gauss_1ch = sum[11:4];  // >>4
        end
    endfunction

    // -----------------------------
    // 4) 출력단: 경계에서는 원본 통과, 내부에서만 Blur
    // -----------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            r_out  <= '0;
            g_out  <= '0;
            b_out  <= '0;
            de_out <= 1'b0;
        end else begin
            de_out <= img_de_d;  // window와 같은 타이밍

            if (img_de_d && (x_d > 2) && (y_d > 2)) begin
                // 내부 영역: 가우시안 적용
                r_out <= gauss_1ch(w_r);
                g_out <= gauss_1ch(w_g);
                b_out <= gauss_1ch(w_b);
            end else begin
                // 경계/blanking: 원본 그대로 (or 0으로 해도 됨)
                r_out <= r_in;
                g_out <= g_in;
                b_out <= b_in;
            end
        end
    end

endmodule
