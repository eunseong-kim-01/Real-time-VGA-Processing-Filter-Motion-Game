`timescale 1ns / 1ps

module MirrorFilter (
    input  logic       mode_quad,   // 0: 전체 화면 (미러/데칼 OFF), 1: 4타일 모드
    input logic [1:0] mirror_sel,  // 01: H 데칼, 10: V 데칼, 11: 둘 다
    input logic [9:0] x_pixel_in,  // VGA 전체 좌표 x (0~639)
    input logic [9:0] y_pixel_in,  // VGA 전체 좌표 y (0~479)
    output logic [9:0] x_pixel_out,
    output logic [9:0] y_pixel_out
);
    // 타일 내 로컬 QVGA 크기
    localparam int H_TILE_MAX = 10'd319;  // 0..319
    localparam int V_TILE_MAX = 10'd239;  // 0..239
    localparam int H_MIDPOINT = 10'd160;  // 320/2
    localparam int V_MIDPOINT = 10'd120;  // 240/2

    // 타일 origin, 로컬 좌표
    logic [9:0] base_x, base_y;
    logic [9:0] local_x, local_y;
    logic [9:0] local_x_dec, local_y_dec;
    logic [9:0] x_mirror, y_mirror;

    always_comb begin
        if (!mode_quad) begin
            // ---------------------------------
            // 1) 전체 화면 모드: 그냥 패스
            // ---------------------------------
            x_pixel_out = x_pixel_in;
            y_pixel_out = y_pixel_in;
        end else begin
            // ---------------------------------
            // 2) 4타일 모드: 타일 기준 데칼코마니
            // ---------------------------------

            // (a) 타일 origin 계산
            if (x_pixel_in < 10'd320) base_x = 10'd0;
            else base_x = 10'd320;

            if (y_pixel_in < 10'd240) base_y = 10'd0;
            else base_y = 10'd240;

            // (b) 타일 내부 로컬 좌표 (0~319, 0~239)
            local_x = x_pixel_in - base_x;
            local_y = y_pixel_in - base_y;

            // (c) 미러 좌표 (타일 기준)
            x_mirror = H_TILE_MAX - local_x;  // 319 - x
            y_mirror = V_TILE_MAX - local_y;  // 239 - y

            // (d) 기본: 데칼 OFF → 그대로
            local_x_dec = local_x;
            local_y_dec = local_y;

            // (e) 가로 데칼 (mirror_sel[0])
            //     왼쪽 절반: 원본, 오른쪽 절반: 왼쪽 거 접어온 것
            if (mirror_sel[0]) begin
                local_x_dec = (local_x < H_MIDPOINT) ? local_x : x_mirror;
            end

            // (f) 세로 데칼 (mirror_sel[1])
            //     위쪽 절반: 원본, 아래쪽 절반: 위쪽 거 접어온 것
            if (mirror_sel[1]) begin
                local_y_dec = (local_y < V_MIDPOINT) ? local_y : y_mirror;
            end

            // (g) 다시 전체 좌표로 복원
            x_pixel_out = base_x + local_x_dec;
            y_pixel_out = base_y + local_y_dec;
        end
    end

endmodule

module RetroFilter (
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);
    // logic [3:0] r_retro = {r_in[3:1], 1'b1};
    // logic [3:0] g_retro = {g_in[3:1], 1'b1};
    // logic [3:0] b_retro = {b_in[3:1], 1'b1};

    logic [3:0] r_retro = {
        r_in[3:2], 2'b11
    };  // R 상위 2비트 사용 (0~15 -> 0, 4, 8, 12 레벨)
    logic [3:0] g_retro = {g_in[3:2], 2'b11};  // G 상위 2비트 사용
    logic [3:0] b_retro = {b_in[3:2], 2'b11};  // B 상위 2비트 사용

    assign r_out = r_retro;
    assign g_out = g_retro;
    assign b_out = b_retro;

endmodule

// module RetroMirrorFilter (
//     input logic [1:0] mode_sel,
//     input logic       retro_sel,
//     input logic [1:0] mirror_sel,

//     input logic [9:0] x_pixel_in,
//     input logic [9:0] y_pixel_in,

//     output logic [9:0] x_pixel_out,
//     output logic [9:0] y_pixel_out,

//     input logic [3:0] r_in,
//     input logic [3:0] g_in,
//     input logic [3:0] b_in,

//     output logic [3:0] r_out,
//     output logic [3:0] g_out,
//     output logic [3:0] b_out
// );
//     logic retro_sel_internal;
//     logic [1:0] mirror_sel_internal;

//     assign retro_sel_internal  = (mode_sel == 2'b10) ? retro_sel : 1'b0;
//     assign mirror_sel_internal = (mode_sel == 2'b10) ? mirror_sel : 2'b00;


//     logic [9:0] x_pixel_blocked;
//     logic [9:0] y_pixel_blocked;
//     logic [9:0] x_pixel_mirrored;
//     logic [9:0] y_pixel_mirrored;

//     logic [3:0] r_retrocolor;
//     logic [3:0] g_retrocolor;
//     logic [3:0] b_retrocolor;

//     logic [1:0] x_pixel_mod_3;
//     logic [1:0] y_pixel_mod_3;

//     assign x_pixel_mod_3   = x_pixel_in % 3;
//     assign y_pixel_mod_3   = y_pixel_in % 3;

//     assign x_pixel_blocked = retro_sel_internal ? (x_pixel_in - x_pixel_mod_3) : x_pixel_in;
//     assign y_pixel_blocked = retro_sel_internal ? (y_pixel_in - y_pixel_mod_3) : y_pixel_in;

//     MirrorFilter U_MirrorFilter (
//         .mirror_sel (mirror_sel_internal),
//         .x_pixel_in (x_pixel_blocked),
//         .y_pixel_in (y_pixel_blocked),
//         .x_pixel_out(x_pixel_mirrored),
//         .y_pixel_out(y_pixel_mirrored)
//     );

//     assign x_pixel_out = x_pixel_mirrored;
//     assign y_pixel_out = y_pixel_mirrored;

//     RetroFilter U_RetroFilter (
//         .retro_sel(retro_sel_internal),
//         .r_in(r_in),
//         .g_in(g_in),
//         .b_in(b_in),
//         .r_out(r_retrocolor),
//         .g_out(g_retrocolor),
//         .b_out(b_retrocolor)
//     );

//     assign r_out = r_retrocolor;
//     assign g_out = g_retrocolor;
//     assign b_out = b_retrocolor;

// endmodule


// module MirrorFilter(
//     input  logic       mode_quad,   // 0: 풀스크린(미러 OFF), 1: 4타일 모드(미러 ON)
//     input  logic [1:0] mirror_sel,  // 01: H, 10: V, 11: H+V
//     input  logic [9:0] x_pixel_in,        // VGA 전체 좌표 x (0~639)
//     input  logic [9:0] y_pixel_in,        // VGA 전체 좌표 y (0~479)
//     output logic [9:0] x_pixel_out,
//     output logic [9:0] y_pixel_out
// );
//     // QVGA 타일 크기
//     localparam int H_TILE_MAX = 10'd319; // 0~319
//     localparam int V_TILE_MAX = 10'd239; // 0~239

//     // 타일 origin, 로컬 좌표
//     logic [9:0] base_x, base_y;
//     logic [9:0] local_x, local_y;
//     logic [9:0] local_x_mir, local_y_mir;

//     always_comb begin
//         if (!mode_quad) begin
//             // ---------------------------------
//             // 1) 풀스크린 모드: 미러 없이 패스
//             // ---------------------------------
//             x_pixel_out = x_pixel_in;
//             y_pixel_out = y_pixel_in;
//         end else begin
//             // ---------------------------------
//             // 2) 4타일 모드: 타일 기준 mirror
//             // ---------------------------------

//             // (a) 현재 픽셀이 속한 타일 origin
//             if (x_pixel_in < 10'd320)
//                 base_x = 10'd0;
//             else
//                 base_x = 10'd320;

//             if (y_pixel_in < 10'd240)
//                 base_y = 10'd0;
//             else
//                 base_y = 10'd240;

//             // (b) 타일 내부 로컬 좌표 (0~319, 0~239)
//             local_x = x_pixel_in - base_x;
//             local_y = y_pixel_in - base_y;

//             // (c) 기본값: 미러 안 했을 때
//             local_x_mir = local_x;
//             local_y_mir = local_y;

//             // (d) 좌우 미러 (mirror_sel[0] == 1)
//             if (mirror_sel[0]) begin
//                 local_x_mir = H_TILE_MAX - local_x; // 319 - x
//             end

//             // (e) 상하 미러 (mirror_sel[1] == 1)
//             if (mirror_sel[1]) begin
//                 local_y_mir = V_TILE_MAX - local_y; // 239 - y
//             end

//             // (f) 다시 전체 좌표로 복원
//             x_pixel_out = base_x + local_x_mir;
//             y_pixel_out = base_y + local_y_mir;
//         end
//     end

// endmodule
