module MiniGame_Top_4way (
    input logic sys_clk,
    input logic reset,
    input logic start,
    input logic vsync,

    input logic DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,

    input logic [3:0] cam_r,
    input logic [3:0] cam_g,
    input logic [3:0] cam_b,

    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out,
    output logic [2:0] fsm_state_deug
);


    logic pass_LT, pass_RT, pass_LB, pass_RB;
    logic [2:0] fsm_state;
    logic [1:0] region;
    logic [1:0] result_type;
    logic [2:0] round_cnt;    
    logic [4:0] round_result;
    logic [2:0] score;  

assign fsm_state_deug = fsm_state;
    
//     // Detector → PASS
  logic [3:0] ck_r, ck_g, ck_b;


    // ChromaKey U_CK (
    //     .clk     (sys_clk),
    //     .reset   (reset),

    //     .i_red   (cam_r),
    //     .i_green (cam_g),
    //     .i_blue  (cam_b),

    //     .x_pixel (x_pixel),
    //     .y_pixel (y_pixel),
    //     .DE      (DE),

    //     .red_port  (ck_r),
    //     .green_port(ck_g),
    //     .blue_port (ck_b)
    // );

    ColorDetector_4way u_cd(
        .clk(sys_clk),
        .vsync(vsync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .r_in(cam_r),
        .g_in(cam_g),
        .b_in(cam_b),
        .pass_LT(pass_LT),
        .pass_RT(pass_RT),
        .pass_LB(pass_LB),
        .pass_RB(pass_RB)
    );


    // ColorDetector_4way u_cd (
    //     .clk    (sys_clk),
    //     .vsync  (vsync),
    //     .DE     (DE),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .r_in   (cam_r),
    //     .g_in   (cam_g),
    //     .b_in   (cam_b),
    //     .pass_LT(pass_LT),
    //     .pass_RT(pass_RT),
    //     .pass_LB(pass_LB),
    //     .pass_RB(pass_RB)
    // );

    // FSM → detect_xx로 PASS_xx 그대로 사용
    

  
    MiniGameFSM_4way U_Game_Core(
    .clk(sys_clk),
    .reset(reset),
    .start(start),
    .vsync(vsync),

    // ColorDetector로부터 입력
    .detect_LT(pass_LT),
    .detect_RT(pass_RT),
    .detect_LB(pass_LB),
    .detect_RB(pass_RB),

    // Overlay로 출력
    .fsm_state(fsm_state),    // IDLE/READY/PLAY/ROUND_END/SCOREBOARD
    .region(region),       // 현재 지시 region
    .result_type(result_type),  // SUCCESS/FAIL
    .round_cnt(round_cnt),    // 현재 라운드 (0~4)
    .score(score),        // 총 점수 (0~5)
    .round_result(round_result)  // 각 라운드 결과 (bit별)
);

    // Overlay
    logic [3:0] ov_r, ov_g, ov_b;
    logic overlay_en;

    GameOverlay_4way U_Game_Overlay(
    .DE(DE),
    .x(x_pixel),
    .y(y_pixel),

    // FSM 입력
    .fsm_state(fsm_state),
    .region(region),
    .result_type(result_type),
    .round_cnt(round_cnt),     // 지금은 사용 안 함 (숫자 미표시)
    .round_result(round_result),
    .score(score),         // 지금은 사용 안 함 (숫자 미표시)

    // 최종 출력
    .r(ov_r),
    .g(ov_g),
    .b(ov_b),
    .overlay_en(overlay_en)
);

    // Output
    assign r_out = overlay_en ? ov_r : cam_r;
    assign g_out = overlay_en ? ov_g : cam_g;
    assign b_out = overlay_en ? ov_b : cam_b;

endmodule