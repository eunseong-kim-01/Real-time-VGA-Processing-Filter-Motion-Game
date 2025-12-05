

`timescale 1ns / 1ps

module MiniGameFSM_4way (
    input logic clk,
    input logic reset,
    input logic start,
    input logic vsync,

    // ColorDetector로부터 입력
    input logic detect_LT,
    input logic detect_RT,
    input logic detect_LB,
    input logic detect_RB,

    // Overlay로 출력
    output logic [2:0] fsm_state,    // IDLE/READY/PLAY/ROUND_END/SCOREBOARD
    output logic [1:0] region,       // 현재 지시 region
    output logic [1:0] result_type,  // SUCCESS/FAIL
    output logic [2:0] round_cnt,    // 현재 라운드 (0~4)
    output logic [2:0] score,        // 총 점수 (0~5)
    output logic [4:0] round_result  // 각 라운드 결과 (bit별)
);

    //==========================================================
    // Type Definitions
    //==========================================================
    typedef enum logic [2:0] {
        IDLE       = 3'b000,
        READY      = 3'b001,
        PLAY       = 3'b010,
        ROUND_END  = 3'b011,
        SCOREBOARD = 3'b100
    } state_t;

    typedef enum logic [1:0] {
        RES_NONE    = 2'b00,
        RES_SUCCESS = 2'b01,
        RES_FAIL    = 2'b10
    } result_t;

    //==========================================================
    // Internal Registers
    //==========================================================
    state_t state, next_state;

    // Timers (frame 단위)
    logic [7:0] ready_timer;
    logic [7:0] play_timer;
    logic [7:0] round_end_timer;
    logic [9:0] score_timer;

    // PLAY state counters
    logic [7:0] hold_cnt;     // 정답 유지 frame 수
    logic [3:0] skip_frames;  // 초기 안정화 frame skip

    // ⭐ 수정 1: 정답 인정 시간을 늘립니다 (15 -> 45 frame, 약 1.5초)
    // 노이즈로 인해 잠깐 정답 처리되는 것을 방지합니다.
    localparam int HOLD_THRESHOLD = 45; 

    // Detect signals (frame-latched)
    logic LT_d, RT_d, LB_d, RB_d;

    // LFSR for random region
    logic [7:0] lfsr;

    // Internal logic
    logic correct;

    //==========================================================
    // vsync Rising Edge Detection
    //==========================================================
    logic vs_d, vs_rise;

    always_ff @(posedge clk) begin
        vs_d    <= vsync;
        vs_rise <= vsync & ~vs_d;
    end

    //==========================================================
    // Detect Signal Latching (frame-based)
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            LT_d <= 0;
            RT_d <= 0;
            LB_d <= 0;
            RB_d <= 0;
        end else if (vs_rise) begin
            LT_d <= detect_LT;
            RT_d <= detect_RT;
            LB_d <= detect_LB;
            RB_d <= detect_RB;
        end
    end

    //==========================================================
    // LFSR (Random Region Generator)
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) lfsr <= 8'hA5;
        else if (vs_rise) lfsr <= {lfsr[6:0], ^(lfsr & 8'hB8)};
    end

    //==========================================================
    // ⭐ 수정 2: 정답 판단 로직을 always_comb + case문으로 명확히 분리
    //==========================================================
    always_comb begin
        correct = 1'b0; // 기본값은 오답
        
        case (region)
            // region 0 (LT): LT만 켜져야 함. RT, LB, RB는 꺼져야 함.
            2'd0: begin
                if (LT_d == 1'b1 && RT_d == 1'b0 && LB_d == 1'b0 && RB_d == 1'b0)
                    correct = 1'b1;
            end

            // region 1 (RT): RT만 켜져야 함.
            2'd1: begin
                if (RT_d == 1'b1 && LT_d == 1'b0 && LB_d == 1'b0 && RB_d == 1'b0)
                    correct = 1'b1;
            end

            // region 2 (LB): LB만 켜져야 함.
            2'd2: begin
                if (LB_d == 1'b1 && LT_d == 1'b0 && RT_d == 1'b0 && RB_d == 1'b0)
                    correct = 1'b1;
            end

            // region 3 (RB): RB만 켜져야 함.
            2'd3: begin
                if (RB_d == 1'b1 && LT_d == 1'b0 && RT_d == 1'b0 && LB_d == 1'b0)
                    correct = 1'b1;
            end
        endcase
    end

    //==========================================================
    // Block 1: State Register
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    //==========================================================
    // Block 2: Next State Logic
    //==========================================================
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start) next_state = READY;
            end

            READY: begin
                if (vs_rise && ready_timer >= 60) next_state = PLAY;
            end

            PLAY: begin
                if (vs_rise) begin
                    // ⭐ 수정 3: 늘어난 Threshold 적용
                    if (hold_cnt >= HOLD_THRESHOLD) next_state = ROUND_END;
                    else if (play_timer >= 120) next_state = ROUND_END;
                end
            end

            ROUND_END: begin
                if (vs_rise && round_end_timer >= 60) begin
                    if (round_cnt < 4) next_state = READY;
                    else next_state = SCOREBOARD;
                end
            end

            SCOREBOARD: begin
                if (vs_rise && score_timer >= 300) next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    //==========================================================
    // Block 3: Sequential Logic
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ready_timer     <= 0;
            play_timer      <= 0;
            round_end_timer <= 0;
            score_timer     <= 0;
            hold_cnt        <= 0;
            skip_frames     <= 0;
            round_cnt       <= 0;
            score           <= 0;
            round_result    <= 0;
            region          <= 0;
            result_type     <= RES_NONE;
        end else begin
            case (state)
                IDLE: begin
                    ready_timer     <= 0;
                    play_timer      <= 0;
                    round_end_timer <= 0;
                    score_timer     <= 0;
                    round_cnt       <= 0;
                    score           <= 0;
                    round_result    <= 0;
                    result_type     <= RES_NONE;
                end

                READY: begin
                    if (vs_rise) begin
                        ready_timer <= ready_timer + 1;
                        if (ready_timer >= 60) begin
                            region      <= lfsr % 4;
                            play_timer  <= 0;
                            hold_cnt    <= 0;
                            skip_frames <= 4;
                        end
                    end
                end

                PLAY: begin
                    if (vs_rise) begin
                        if (skip_frames != 0) begin
                            skip_frames <= skip_frames - 1;
                        end else begin
                            play_timer <= play_timer + 1;

                            // correct 로직은 always_comb에서 처리됨
                            if (correct) hold_cnt <= hold_cnt + 1;
                            else hold_cnt <= 0; // 조건 불만족 시 즉시 리셋

                            // ⭐ 수정 4: Threshold 변경
                            if (hold_cnt >= HOLD_THRESHOLD) begin
                                result_type             <= RES_SUCCESS;
                                score                   <= score + 1;
                                round_result[round_cnt] <= 1;
                                round_end_timer         <= 0;
                            end 
                            else if (play_timer >= 120) begin
                                result_type             <= RES_FAIL;
                                round_result[round_cnt] <= 0;
                                round_end_timer         <= 0;
                            end
                        end
                    end
                end

                ROUND_END: begin
                    if (vs_rise) begin
                        round_end_timer <= round_end_timer + 1;
                        if (round_end_timer >= 60) begin
                            if (round_cnt < 4) begin
                                round_cnt   <= round_cnt + 1;
                                ready_timer <= 0;
                                result_type <= RES_NONE;
                            end else begin
                                score_timer <= 0;
                            end
                        end
                    end
                end

                SCOREBOARD: begin
                    if (vs_rise) begin
                        score_timer <= score_timer + 1;
                    end
                end
            endcase
        end
    end

    assign fsm_state = state;

endmodule