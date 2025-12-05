`timescale 1ns / 1ps
// module ImgMemReader (
//     input  logic                         DE,
//     input  logic [                  9:0] x_pixel,
//     input  logic [                  9:0] y_pixel,
//     output logic [$clog2(320*240)-1 : 0] addr,
//     input  logic [                 15:0] imgData,
//     output logic [                  3:0] r_port,
//     output logic [                  3:0] g_port,
//     output logic [                  3:0] b_port
// );

//     assign addr = DE ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 'bz;
//     assign {r_port, g_port, b_port} = DE ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;

// endmodule

`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                         DE,
    input  logic [9:0]                   x_pixel,
    input  logic [9:0]                   y_pixel,
    input  logic                         output_sel,   // 0: 2x 업스케일, 1: 4타일 모드

    output logic [$clog2(320*240)-1 : 0] addr,
    input  logic [15:0]                  imgData,     // RGB565 가정
    output logic [3:0]                   r_port,
    output logic [3:0]                   g_port,
    output logic [3:0]                   b_port
);
    // -------------------------
    // 1) 유효 화면 영역 체크
    // -------------------------
    logic img_display_en;

    always_comb begin
        img_display_en = DE &&
                         (x_pixel < 10'd640) &&
                         (y_pixel < 10'd480);
    end

    // -------------------------
    // 2) 샘플링 좌표 선택
    //    (업스케일 vs 4타일)
    // -------------------------
    logic [8:0] x_sample;  // 0~319
    logic [7:0] y_sample;  // 0~239

    always_comb begin
        // default
        x_sample = '0;
        y_sample = '0;

        if (img_display_en) begin
            if (output_sel) begin
                // -----------------------------
                // 4타일 모드: 좌표 fold
                // -----------------------------
                // x_local
                if (x_pixel < 10'd320)
                    x_sample = x_pixel[8:0];
                else
                    x_sample = x_pixel[8:0] - 9'd320;

                // y_local
                if (y_pixel < 10'd240)
                    y_sample = y_pixel[7:0];
                else
                    y_sample = y_pixel[7:0] - 8'd240;

            end else begin
                // -----------------------------
                // 기존 2x 업스케일 모드
                // QVGA(320x240) → VGA(640x480)
                // -----------------------------
                // x: 0~639 -> 0~319
                x_sample = x_pixel[9:1];   // /2

                // y: 0~479 -> 0~239
                // y_pixel[8:1] == (y_pixel >> 1)[7:0]
                y_sample = y_pixel[8:1];   // /2
            end
        end
    end

    // -------------------------
    // 3) Frame Buffer 주소 계산
    //    addr = 320 * y + x
    //    320 = 256 + 64
    // -------------------------
    always_comb begin
        if (img_display_en) begin
            addr = ( (y_sample << 8) + (y_sample << 6) ) + x_sample;
        end else begin
            addr = '0;  // 또는 이전값 유지해도 됨
        end
    end

    // -------------------------
    // 4) RGB 출력
    // -------------------------
    logic [3:0] r_int;
    logic [3:0] g_int;
    logic [3:0] b_int;

    always_comb begin
        if (img_display_en) begin
            // RGB565 → RGB444 (예시)
            r_int = imgData[15:12];
            g_int = imgData[10:7];
            b_int = imgData[4:1];
        end else begin
            r_int = 4'd0;
            g_int = 4'd0;
            b_int = 4'd0;
        end
    end

    assign r_port = r_int;
    assign g_port = g_int;
    assign b_port = b_int;

endmodule






