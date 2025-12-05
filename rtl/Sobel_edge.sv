// `timescale 1ns / 1ps

// module Sobel_edge #(
//     parameter int H_RES = 640
// ) (
//     input  logic       clk,
//     input  logic       reset,

//     // Gaussian Side
//     input  logic       de_in,
//     input  logic [9:0] x_in,
//     input  logic [9:0] y_in,
//     input  logic [3:0] r_in,
//     input  logic [3:0] g_in,
//     input  logic [3:0] b_in,

//     // output 
//     output logic       de_out,
//     output logic [3:0] r_out,
//     output logic [3:0] g_out,
//     output logic [3:0] b_out
// );
//     // Sobel magnitude threshold
//     localparam logic [7:0] TH_EDGE = 8'd16;  // 필요시 조절

//     // -------------------------------------------------
//     // 1) GRAY 변환: 4bit RGB → 6bit Grayscale
//     // -------------------------------------------------
//     logic [6:0] gray_tmp;
//     logic [5:0] gray_in;  // 0~63

//     always_comb begin
//         gray_tmp = r_in + (g_in << 1) + b_in;  // 0~60
//         gray_in  = gray_tmp[5:0];  // 6bit 유지
//     end

//     // -------------------------------------------------
//     // 2) Line buffer (이전/현재 라인, GRAY 한 채널만, 6bit)
//     // -------------------------------------------------
//     logic [5:0] line0[0:H_RES-1];  // y-1
//     logic [5:0] line1[0:H_RES-1];  // y

//     // 3x3 윈도우 (GRAY, 6bit)
//     logic [5:0] w[0:2][0:2];

//     // DE/x/y 파이프라인 및 line_start
//     logic       de_d;
//     logic [9:0] x_d, y_d;
//     wire        line_start = de_in && (x_in == 10'd0);

//     // -------------------------------------------------
//     // 3) line buffer + 3x3 window 업데이트
//     // -------------------------------------------------
//     integer i, j;
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             for (i = 0; i < 3; i++) begin
//                 for (j = 0; j < 3; j++) begin
//                     w[i][j] <= '0;
//                 end
//             end
//         end else if (de_in) begin
//             // (1) 세로 2줄 버퍼 갱신
//             line0[x_in] <= line1[x_in];
//             line1[x_in] <= gray_in;

//             if (line_start) begin
//                 // 새 라인 시작: window 초기화
//                 for (i = 0; i < 3; i++) begin
//                     for (j = 0; j < 3; j++) begin
//                         w[i][j] <= '0;
//                     end
//                 end
//             end else begin
//                 // (2) 3x3 윈도우: 왼쪽으로 쉬프트 후 새 값 채움
//                 // 윗줄: line0
//                 w[0][0] <= w[0][1];
//                 w[0][1] <= w[0][2];
//                 w[0][2] <= line0[x_in];
//                 // 중간줄: line1
//                 w[1][0] <= w[1][1];
//                 w[1][1] <= w[1][2];
//                 w[1][2] <= line1[x_in];
//                 // 아랫줄: 현재 픽셀(gray_in)
//                 w[2][0] <= w[2][1];
//                 w[2][1] <= w[2][2];
//                 w[2][2] <= gray_in;
//             end
//         end
//     end

//     // de / x / y 1cycle delay (w와 정렬용)
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             de_d <= 1'b0;
//             x_d  <= '0;
//             y_d  <= '0;
//         end else begin
//             de_d <= de_in;
//             if (de_in) begin
//                 x_d <= x_in;
//                 y_d <= y_in;
//             end
//         end
//     end

//     // -------------------------------------------------
//     // 4) Sobel core (GX,GY + |GX|+|GY|)
//     // -------------------------------------------------
//     logic signed [9:0] gx, gy;
//     logic       [9:0] abs_gx, abs_gy;
//     logic       [9:0] mag10;  // 10bit magnitude (최대 ~504)
//     logic       [7:0] mag8;

//     logic       is_edge;      // 1픽셀짜리 엣지 마스크 (기본)
//     logic       is_edge_d;    // 1cycle delayed (de_d와 정렬)

//     always_comb begin
//         // signed 연산 위해 6bit(gray) → 10bit로 zero-extend 후 사용
//         gx = -$signed({4'b0, w[0][0]}) - ($signed({4'b0, w[1][0]}) <<< 1) -
//              $signed({4'b0, w[2][0]}) + $signed({4'b0, w[0][2]}) + ($signed({4'b0, w[1][2]}) <<< 1) +
//              $signed({4'b0, w[2][2]});

//         gy = -$signed({4'b0, w[0][0]}) - ($signed({4'b0, w[0][1]}) <<< 1) -
//              $signed({4'b0, w[0][2]}) + $signed({4'b0, w[2][0]}) + ($signed({4'b0, w[2][1]}) <<< 1) +
//              $signed({4'b0, w[2][2]});

//         // 절대값
//         abs_gx = gx[9] ? -gx : gx;
//         abs_gy = gy[9] ? -gy : gy;

//         mag10 = abs_gx + abs_gy;  // 최대 ~504

//         // 8bit로 saturation
//         if (mag10 > 10'd255) mag8 = 8'hFF;
//         else mag8 = mag10[7:0];

//         // 명시적 threshold
//         is_edge = (mag8 >= TH_EDGE);
//     end

//     // -------------------------------------------------
//     // 5) 엣지 두께 2픽셀 (가로 방향 dilation)
//     //    thick_edge = is_edge(x) | is_edge(x-1)
//     // -------------------------------------------------
//     logic edge_now, edge_d1;  // 현재, 직전 픽셀의 엣지 정보
//     logic thick_edge;         // 두껍게 만든 엣지 마스크

//     always_ff @(posedge clk) begin
//         if (reset) begin
//             de_out     <= 1'b0;
//             r_out      <= '0;
//             g_out      <= '0;
//             b_out      <= '0;

//             is_edge_d  <= 1'b0;
//             edge_now   <= 1'b0;
//             edge_d1    <= 1'b0;
//             thick_edge <= 1'b0;
//         end else begin
//             // is_edge를 1cycle 딜레이해서 de_d와 정렬
//             is_edge_d <= is_edge;
//             de_out    <= de_d;

//             // 1) is_edge 시프트 (가로 2탭)
//             if (de_d) begin
//                 edge_d1  <= edge_now;
//                 edge_now <= is_edge_d;
//             end else begin
//                 edge_now <= 1'b0;
//                 edge_d1  <= 1'b0;
//             end

//             // 2) 두께 2픽셀: 현재 + 왼쪽 1픽셀 OR
//             thick_edge <= edge_now | edge_d1;

//             // 3) 출력 RGB (엣지면 흰색, 아니면 검정)
//             if (de_d && (x_d > 4) && (y_d > 4)) begin
//                 if (thick_edge) begin
//                     r_out <= 4'hF;
//                     g_out <= 4'hF;
//                     b_out <= 4'hF;
//                 end else begin
//                     r_out <= 4'd0;
//                     g_out <= 4'd0;
//                     b_out <= 4'd0;
//                 end
//             end else begin
//                 r_out <= 4'd0;
//                 g_out <= 4'd0;
//                 b_out <= 4'd0;
//             end
//         end
//     end

// endmodule
`timescale 1ns / 1ps

module Sobel_edge #(
    parameter int H_RES = 640
) (
    input  logic       clk,
    input  logic       reset,

    // Gaussian Side
    input  logic       de_in,
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,

    // output 
    output logic       de_out,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);
    // Sobel magnitude threshold
    localparam logic [7:0] TH_EDGE = 8'd16;  // 필요시 조절

    // -------------------------------------------------
    // 0) 안전 영역용 DE (프레임 테두리 몇 픽셀 잘라내기)
    //     x: 2 ~ H_RES-3
    //     y: 2 ~ 477
    // -------------------------------------------------
    logic safe_de;

    assign safe_de = de_in
                  && (x_in >= 10'd2)
                  && (y_in >= 10'd2)
                  && (x_in <  H_RES - 2)
                  && (y_in <  10'd478);

    // -------------------------------------------------
    // 1) GRAY 변환: 4bit RGB → 6bit Grayscale
    // -------------------------------------------------
    logic [6:0] gray_tmp;
    logic [5:0] gray_in;  // 0~63

    always_comb begin
        gray_tmp = r_in + (g_in << 1) + b_in;  // 0~60
        gray_in  = gray_tmp[5:0];              // 6bit 유지
    end

    // -------------------------------------------------
    // 2) Line buffer (이전/현재 라인, GRAY 한 채널만, 6bit)
    //      → 여기는 de_in 기준 그대로 유지 (전체 프레임 버퍼링)
    // -------------------------------------------------
    logic [5:0] line0[0:H_RES-1];  // y-1
    logic [5:0] line1[0:H_RES-1];  // y

    // 3x3 윈도우 (GRAY, 6bit)
    logic [5:0] w[0:2][0:2];

    // line_start: 원본 de 기준
    wire line_start = de_in && (x_in == 10'd0);

    integer i, j;
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3; j++) begin
                    w[i][j] <= '0;
                end
            end
        end else if (de_in) begin
            // (1) 세로 2줄 버퍼 갱신
            line0[x_in] <= line1[x_in];
            line1[x_in] <= gray_in;

            if (line_start) begin
                // 새 라인 시작: window 초기화
                for (i = 0; i < 3; i++) begin
                    for (j = 0; j < 3; j++) begin
                        w[i][j] <= '0;
                    end
                end
            end else begin
                // (2) 3x3 윈도우: 왼쪽으로 쉬프트 후 새 값 채움
                // 윗줄: line0
                w[0][0] <= w[0][1];
                w[0][1] <= w[0][2];
                w[0][2] <= line0[x_in];
                // 중간줄: line1
                w[1][0] <= w[1][1];
                w[1][1] <= w[1][2];
                w[1][2] <= line1[x_in];
                // 아랫줄: 현재 픽셀(gray_in)
                w[2][0] <= w[2][1];
                w[2][1] <= w[2][2];
                w[2][2] <= gray_in;
            end
        end
    end

    // -------------------------------------------------
    // 3) de / x / y 1cycle delay (이제 safe_de 기준)
    // -------------------------------------------------
    logic       de_d;
    logic [9:0] x_d, y_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            de_d <= 1'b0;
            x_d  <= '0;
            y_d  <= '0;
        end else begin
            de_d <= safe_de;       // ★ 수정: safe_de 기준
            if (safe_de) begin     // ★ 수정
                x_d <= x_in;
                y_d <= y_in;
            end
        end
    end

    // -------------------------------------------------
    // 4) Sobel core (GX,GY + |GX|+|GY|)
    // -------------------------------------------------
    logic signed [9:0] gx, gy;
    logic       [9:0] abs_gx, abs_gy;
    logic       [9:0] mag10;  // 10bit magnitude (최대 ~504)
    logic       [7:0] mag8;

    logic       is_edge;      // 1픽셀짜리 엣지 마스크 (기본)

    always_comb begin
        // signed 연산 위해 6bit(gray) → 10bit로 zero-extend 후 사용
        gx = -$signed({4'b0, w[0][0]}) - ($signed({4'b0, w[1][0]}) <<< 1) -
              $signed({4'b0, w[2][0]}) + $signed({4'b0, w[0][2]}) +
             ($signed({4'b0, w[1][2]}) <<< 1) + $signed({4'b0, w[2][2]});

        gy = -$signed({4'b0, w[0][0]}) - ($signed({4'b0, w[0][1]}) <<< 1) -
              $signed({4'b0, w[0][2]}) + $signed({4'b0, w[2][0]}) +
             ($signed({4'b0, w[2][1]}) <<< 1) + $signed({4'b0, w[2][2]});

        // 절대값
        abs_gx = gx[9] ? -gx : gx;
        abs_gy = gy[9] ? -gy : gy;

        mag10 = abs_gx + abs_gy;  // 최대 ~504

        // 8bit로 saturation
        if (mag10 > 10'd255) mag8 = 8'hFF;
        else                 mag8 = mag10[7:0];

        // 명시적 threshold
        is_edge = (mag8 >= TH_EDGE);
    end

    // -------------------------------------------------
    // 5) 엣지 두께 2픽셀 (가로 방향 dilation)
    //    thick_edge = is_edge(x) | is_edge(x-1)
    //    + 라인 시작(x_d==0)에서 edge 시프트 초기화
    // -------------------------------------------------
    logic is_edge_d;           // is_edge 1cycle delay (de_d와 정렬)
    logic edge_now, edge_d1;   // 현재, 직전 픽셀의 엣지 정보
    logic thick_edge;          // 두껍게 만든 엣지 마스크

    always_ff @(posedge clk) begin
        if (reset) begin
            de_out     <= 1'b0;
            r_out      <= '0;
            g_out      <= '0;
            b_out      <= '0;

            is_edge_d  <= 1'b0;
            edge_now   <= 1'b0;
            edge_d1    <= 1'b0;
            thick_edge <= 1'b0;
        end else begin
            // 0) de / is_edge 동기화
            is_edge_d <= is_edge;
            de_out    <= de_d;

            // 1) 가로 방향 edge 시프트
            if (de_d) begin
                // 새 라인 시작에서는 이전 라인 정보 끊기
                if (x_d == 10'd0) begin
                    edge_now <= 1'b0;
                    edge_d1  <= 1'b0;
                end else begin
                    edge_d1  <= edge_now;
                    edge_now <= is_edge_d;
                end
            end else begin
                edge_now <= 1'b0;
                edge_d1  <= 1'b0;
            end

            // 2) 두께 2픽셀: 현재 + 왼쪽 1픽셀 OR
            thick_edge <= edge_now | edge_d1;

            // 3) 출력 RGB (엣지면 흰색, 아니면 검정)
            //    x_d / y_d는 이미 safe_de로 내부 영역만 들어옴
            if (de_d && (x_d >= 10'd2) && (y_d >= 10'd2)) begin
                if (thick_edge) begin
                    r_out <= 4'hF;
                    g_out <= 4'hF;
                    b_out <= 4'hF;
                end else begin
                    r_out <= 4'd0;
                    g_out <= 4'd0;
                    b_out <= 4'd0;
                end
            end else begin
                r_out <= 4'd0;
                g_out <= 4'd0;
                b_out <= 4'd0;
            end
        end
    end

endmodule
