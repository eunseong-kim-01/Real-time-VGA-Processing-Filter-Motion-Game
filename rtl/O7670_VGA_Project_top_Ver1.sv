module O7670_VGA_Project_top_Ver1 (
    // Global signals
    input logic clk,
    input logic reset,

    // ========================================
    // ✅ 모드 선택 (2비트)
    // ========================================
    input logic [1:0] output_sel,  // 00=Filter, 01=Game, 10=Cartoon

    // ========================================
    // 필터 제어
    // ========================================
    input logic       quad_sel,   // 4분할 필터 모드 (output_sel=00일 때)
    input logic       on_off,     // Cartoon 필터 on/off (output_sel=10일 때)
    input logic [1:0] mirror_sel, // 미러/데칼코마니 (quad_sel=1일 때)

    // ========================================
    // 게임 제어
    // ========================================
    input logic game_str,  // 게임 시작 (output_sel=01일 때)

    // ========================================
    // OV7670 & SCCB
    // ========================================
    input  logic       start,  // SCCB 설정 시작
    output logic       busy,
    done,
    output logic       xclk,
    input  logic       pclk,
    href,
    vsync,
    input  logic [7:0] data,
    output logic       scl,
    inout  tri         sda,

    // ========================================
    // VGA 출력
    // ========================================
    output logic       v_sync,
    h_sync,
    output logic [3:0] r_port,
    g_port,
    b_port
);

    // ========================================
    // 내부 신호
    // ========================================
    logic [15:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
    logic sys_clk;
    logic [3:0] r_raw, g_raw, b_raw;
    logic [9:0] x_pixel, y_pixel, x_raw, y_raw;
    logic DE;

    logic [3:0] r_blur, g_blur, b_blur;
    logic [3:0] r_edge, g_edge, b_edge;
    logic [3:0] r_gray, g_gray, b_gray;
    logic [3:0] r_retro, g_retro, b_retro;
    logic [3:0] r_cart, g_cart, b_cart;
    logic [11:0] filtered_data;

    logic [3:0] r_filterd, g_filterd, b_filterd;
    logic [3:0] r_last, g_last, b_last;
    logic [3:0] r_game, g_game, b_game;

    // ========================================
    // ✅ 모드 디코딩
    // ========================================
    typedef enum logic [1:0] {
        MODE_FILTER  = 2'b00,
        MODE_GAME    = 2'b01,
        MODE_CARTOON = 2'b10,
        MODE_RESERVE = 2'b11
    } mode_t;

    mode_t current_mode;
    assign current_mode = mode_t'(output_sel);

    // 제어 신호 생성
    logic is_filter_mode;
    logic is_game_mode;
    logic is_cartoon_mode;
    logic quad_en_internal;

    assign is_filter_mode  = (current_mode == MODE_FILTER);
    assign is_game_mode    = (current_mode == MODE_GAME);
    assign is_cartoon_mode = (current_mode == MODE_CARTOON);

    // ✅ 4분할은 필터 모드 + quad_sel=1일 때만
    assign quad_en_internal = is_filter_mode && quad_sel;

    // ========================================
    // 3x3 픽셀 윈도우 추출
    // ========================================
    wire [3:0] r_center = p11[15:12];
    wire [3:0] g_center = p11[11:8];
    wire [3:0] b_center = p11[7:4];

    wire [3:0] r_right = p12[15:12];
    wire [3:0] g_right = p12[11:8];
    wire [3:0] b_right = p12[7:4];

    wire [3:0] r_down = p21[15:12];
    wire [3:0] g_down = p21[11:8];
    wire [3:0] b_down = p21[7:4];

    // ========================================
    // 모듈 인스턴스
    // ========================================

    // OV7670 I2C 초기화
    ov7670_I2C_Top U_OV7670_CTRL_TOP (.*);

    // VGA Core (카메라 → 프레임버퍼 → VGA)
    VGA_CORE U_VGA_Core (
        .clk       (clk),
        .reset     (reset),
        .output_sel(quad_en_internal),  // ✅ 4분할 좌표 변환
        .cart_sel  (1'b0),              // ✅ 사용 안 함 (핀 재활용)
        .mirror_sel(mirror_sel),
        .pclk      (pclk),
        .href      (href),
        .vsync     (vsync),
        .data      (data),
        .xclk      (xclk),
        .sys_clk   (sys_clk),
        .h_sync    (h_sync),
        .v_sync    (v_sync),
        .DE        (DE),
        .o_x_pixel (x_pixel),
        .o_y_pixel (y_pixel),
        .r_raw     (r_raw),
        .g_raw     (g_raw),
        .b_raw     (b_raw),
        .pix00     (p00),
        .pix01     (p01),
        .pix02     (p02),
        .pix10     (p10),
        .pix11     (p11),
        .pix12     (p12),
        .pix20     (p20),
        .pix21     (p21),
        .pix22     (p22),
        .x_raw     (x_raw),
        .y_raw     (y_raw)
    );

    // 필터 처리
    Filter_top U_FILTER_TOP (
        .sys_clk(sys_clk),
        .reset(reset),
        .r_raw(r_raw),
        .g_raw(g_raw),
        .b_raw(b_raw),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .r_gray(r_gray),
        .g_gray(g_gray),
        .b_gray(b_gray),
        .filtered_data(filtered_data),
        .r_blur(r_blur),
        .g_blur(g_blur),
        .b_blur(b_blur),
        .r_edge(r_edge),
        .g_edge(g_edge),
        .b_edge(b_edge),
        .r_retro(r_retro),
        .g_retro(g_retro),
        .b_retro(b_retro),
        .on_off(on_off),  // ✅ Cartoon 필터 enable
        .r_in(r_center),
        .g_in(g_center),
        .b_in(b_center),
        .r_right(r_right),
        .g_right(g_right),
        .b_right(b_right),
        .r_down(r_down),
        .g_down(g_down),
        .b_down(b_down),
        .r_cart(r_cart),
        .g_cart(g_cart),
        .b_cart(b_cart)
    );

    // 미니게임
    MiniGame_Top_4way U_GAME (
        .sys_clk(sys_clk),
        .reset(reset),
        .start(game_str),  // ✅ 게임 시작
        .vsync(vsync),
        .DE(DE),
        .x_pixel(x_raw),
        .y_pixel(y_raw),
        .cam_r(r_raw),
        .cam_g(g_raw),
        .cam_b(b_raw),
        .r_out(r_game),
        .g_out(g_game),
        .b_out(b_game)
    );

    // 4분할 필터 MUX
    QuadFilterMux U_QUAD_FILTER_MUX (
        .DE_in(DE),
        .mode_quad(quad_en_internal),  // ✅ 필터 모드 + quad_sel
        .x_in(x_pixel),
        .y_in(y_pixel),
        .r_f0(r_edge),
        .g_f0(g_edge),
        .b_f0(b_edge),
        .r_f1(filtered_data[11:8]),
        .g_f1(filtered_data[7:4]),
        .b_f1(filtered_data[3:0]),
        .r_f2(r_retro),
        .g_f2(g_retro),
        .b_f2(b_retro),
        .r_f3(r_blur),
        .g_f3(g_blur),
        .b_f3(b_blur),
        .r_out(r_filterd),
        .g_out(g_filterd),
        .b_out(b_filterd)
    );

    // 십자선 오버레이
    Quad_Cross_Overlay #(
        .H_RES  (640),
        .V_RES  (480),
        .LINE_TH(3),
        .R_LINE (4'h0),
        .G_LINE (4'hF),
        .B_LINE (4'hF)
    ) U_O_Over (
        .DE_in(DE && quad_en_internal),  // ✅ 4분할 모드에서만
        .x_in (x_raw),
        .y_in (y_raw),
        .r_in (r_filterd),
        .g_in (g_filterd),
        .b_in (b_filterd),
        .r_out(r_last),
        .g_out(g_last),
        .b_out(b_last)
    );

    // 최종 출력 MUX
    mux_3x1 U_Mux_3x1 (
        .sel(output_sel),
        .x0 ({r_last, g_last, b_last}),  // 00: Filter
        .x1 ({r_game, g_game, b_game}),  // 01: Game
        .x2 ({r_cart, g_cart, b_cart}),  // 10: Cartoon
        .y  ({r_port, g_port, b_port})
    );

endmodule

module QuadFilterMux (
    input logic       DE_in,
    input logic       mode_quad,  // 0: 전체 한 필터, 1: 4타일별 다른 필터
    input logic [9:0] x_in,       // 필터 딜레이에 align된 x (0~639)
    input logic [9:0] y_in,       // 필터 딜레이에 align된 y (0~479)

    // Filter 0 (예: 원본 or Gray)
    input logic [3:0] r_f0,
    input logic [3:0] g_f0,
    input logic [3:0] b_f0,

    // Filter 1 (예: Gaussian)
    input logic [3:0] r_f1,
    input logic [3:0] g_f1,
    input logic [3:0] b_f1,

    // Filter 2 (예: Sobel)
    input logic [3:0] r_f2,
    input logic [3:0] g_f2,
    input logic [3:0] b_f2,

    // Filter 3 (예: Retro / Rainbow 등)
    input logic [3:0] r_f3,
    input logic [3:0] g_f3,
    input logic [3:0] b_f3,

    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);
    logic Q0, Q1, Q2, Q3;

    always_comb begin
        Q0 = (x_in < 10'd320) && (y_in < 10'd240);  // 좌상
        Q1 = (x_in >= 10'd320) && (y_in < 10'd240);  // 우상
        Q2 = (x_in < 10'd320) && (y_in >= 10'd240);  // 좌하
        Q3 = (x_in >= 10'd320) && (y_in >= 10'd240);  // 우하
    end

    always_comb begin
        r_out = 4'd0;
        g_out = 4'd0;
        b_out = 4'd0;

        if (DE_in) begin
            if (!mode_quad) begin
                r_out = r_f0;
                g_out = g_f0;
                b_out = b_f0;
            end else begin
                if (Q0) begin
                    // left top
                    r_out = r_f0;
                    g_out = g_f0;
                    b_out = b_f0;
                end else if (Q1) begin
                    // right top
                    r_out = r_f1;
                    g_out = g_f1;
                    b_out = b_f1;
                end else if (Q2) begin
                    // left bottom
                    r_out = r_f2;
                    g_out = g_f2;
                    b_out = b_f2;
                end else begin
                    // right bottom 
                    r_out = r_f3;
                    g_out = g_f3;
                    b_out = b_f3;
                end
            end
        end
    end

endmodule



// module mux_6x1 (
//     input  logic [ 2:0] sel,
//     input  logic [11:0] x0,
//     input  logic [11:0] x1,
//     input  logic [11:0] x2,
//     input  logic [11:0] x3,
//     input  logic [11:0] x4,
//     input  logic [11:0] x5,
//     output logic [11:0] y
// );
//     always_comb begin
//         y = x0;
//         case (sel)
//             3'd0: y = x0;
//             3'd1: y = x1;
//             3'd2: y = x2;
//             3'd3: y = x3;
//             3'd4: y = x4;
//             3'd5: y = x5;
//         endcase
//     end

// endmodule

module mux_3x1 (
    input  logic [ 1:0] sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    output logic [11:0] y
);
    always_comb begin
        y = x0;
        case (sel)
            2'd0: y = x0;
            2'd1: y = x1;
            2'd2: y = x2;
        endcase

    end
endmodule
