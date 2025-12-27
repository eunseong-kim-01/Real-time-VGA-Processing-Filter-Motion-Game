`timescale 1ns / 1ps

module MiniGameFSM_4way (
    input logic clk,
    input logic reset,
    input logic start,
    input logic vsync,

    // Input from ColorDetector
    input logic detect_LT,
    input logic detect_RT,
    input logic detect_LB,
    input logic detect_RB,

    // Output to Overlay
    output logic [2:0] fsm_state,    // IDLE/READY/PLAY/ROUND_END/SCOREBOARD
    output logic [1:0] region,       // Current target region
    output logic [1:0] result_type,  // SUCCESS/FAIL
    output logic [2:0] round_cnt,    // Current round (0~4)
    output logic [2:0] score,        // Total score (0~5)
    output logic [4:0] round_result  // Result of each round (bit-wise)
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

    // Timers (Frame-based)
    logic [7:0] ready_timer;
    logic [7:0] play_timer;
    logic [7:0] round_end_timer;
    logic [9:0] score_timer;

    // PLAY state counters
    logic [7:0] hold_cnt;     // Frames held for correct answer
    logic [3:0] skip_frames;  // Initial stabilization frame skip

    // Threshold for valid answer (approx 1.5s @ 60fps)
    localparam int HOLD_THRESHOLD = 45; 

    // Detect signals (frame-latched)
    logic LT_d, RT_d, LB_d, RB_d;

    // LFSR for random region
    logic [7:0] lfsr;

    // Internal logic
    logic correct;

    //==========================================================
    // ⭐ vsync 2-stage Synchronizer & Rising Edge Detection
    // This part ensures CDC reliability by preventing metastability.
    //==========================================================
    logic vs_sync0, vs_sync1, vs_rise;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            vs_sync0 <= 1'b0;
            vs_sync1 <= 1'b0;
            vs_rise  <= 1'b0;
        end else begin
            vs_sync0 <= vsync;    // 1st stage: Captures asynchronous vsync
            vs_sync1 <= vs_sync0; // 2nd stage: Stabilizes the signal
            // Generates a pulse on the rising edge of the synchronized signal
            vs_rise  <= vs_sync0 & ~vs_sync1; 
        end
    end

    //==========================================================
    // Detect Signal Latching (Sync with vs_rise)
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            LT_d <= 0; RT_d <= 0; LB_d <= 0; RB_d <= 0;
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
    // Correct Answer Logic (Combinational)
    //==========================================================
    always_comb begin
        correct = 1'b0; 
        case (region)
            2'd0: if (LT_d && !RT_d && !LB_d && !RB_d) correct = 1'b1;
            2'd1: if (RT_d && !LT_d && !LB_d && !RB_d) correct = 1'b1;
            2'd2: if (LB_d && !LT_d && !RT_d && !RB_d) correct = 1'b1;
            2'd3: if (RB_d && !LT_d && !RT_d && !LB_d) correct = 1'b1;
        endcase
    end

    //==========================================================
    // FSM: State Register
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    //==========================================================
    // FSM: Next State Logic
    //==========================================================
    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = READY;
            READY: if (vs_rise && ready_timer >= 60) next_state = PLAY;
            PLAY: begin
                if (vs_rise) begin
                    if (hold_cnt >= HOLD_THRESHOLD || play_timer >= 120) 
                        next_state = ROUND_END;
                end
            end
            ROUND_END: begin
                if (vs_rise && round_end_timer >= 60) begin
                    next_state = (round_cnt < 4) ? READY : SCOREBOARD;
                end
            end
            SCOREBOARD: if (vs_rise && score_timer >= 300) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    //==========================================================
    // FSM: Sequential Logic (Timers & Scores)
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            {ready_timer, play_timer, round_end_timer, score_timer} <= 0;
            {hold_cnt, skip_frames, round_cnt, score, round_result} <= 0;
            region <= 0; result_type <= RES_NONE;
        end else begin
            case (state)
                IDLE: begin
                    {ready_timer, play_timer, round_end_timer, score_timer} <= 0;
                    {round_cnt, score, round_result} <= 0;
                    result_type <= RES_NONE;
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
                        if (skip_frames != 0) skip_frames <= skip_frames - 1;
                        else begin
                            play_timer <= play_timer + 1;
                            if (correct) hold_cnt <= hold_cnt + 1;
                            else hold_cnt <= 0;

                            if (hold_cnt >= HOLD_THRESHOLD) begin
                                result_type             <= RES_SUCCESS;
                                score                   <= score + 1;
                                round_result[round_cnt] <= 1;
                                round_end_timer         <= 0;
                            end else if (play_timer >= 120) begin
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
                            end else score_timer <= 0;
                        end
                    end
                end

                SCOREBOARD: if (vs_rise) score_timer <= score_timer + 1;
            endcase
        end
    end

    assign fsm_state = state;

endmodule
