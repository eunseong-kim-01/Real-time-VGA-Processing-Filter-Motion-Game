`timescale 1ns / 1ps

module ov7670_SCCB_Controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    // state
    output logic        busy,
    output logic        done,
    // Rom Side
    output logic [ 6:0] rom_addr,
    input  logic [15:0] rom_data,
    // I2C Master Side
    input  logic        tx_ready,
    output logic        I2C_EN,
    output logic        I2C_START,
    output logic        I2C_STOP,
    output logic [ 7:0] tx_data
);
    localparam logic [7:0] OV7670_ADDR_WR = 8'h42;
    parameter int DELAY_CYCLES = 1_000_000;

    logic [7:0] reg_cur, reg_next;
    logic [7:0] val_cur, val_next;
    logic [$clog2(DELAY_CYCLES)-1:0] delay_cnt, delay_cnt_next;

    typedef enum {
        S_IDLE,
        S_FETCH,
        S_CHECK,
        S_DELAY,
        S_SEND_ADDR,
        S_WAIT_ADDR,
        S_SEND_REG,
        S_WAIT_REG,
        S_SEND_VAL,
        S_WAIT_VAL,
        S_ISSUE_STOP,
        S_WAIT_STOP,
        S_NEXT,
        S_DONE
    } state_e;
    state_e cur, next;
    // next state logic
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cur <= S_IDLE;
            rom_addr <= 0;
            reg_cur <= 8'h00;
            val_cur <= 8'h00;
            delay_cnt <= 0;
        end else begin
            cur <= next;
            rom_addr <= rom_addr + (next == S_NEXT);
            reg_cur <= reg_next;
            val_cur <= val_next;
            delay_cnt <= delay_cnt_next;
        end
    end
    // output comb logic
    always_comb begin
        next = cur;
        reg_next = reg_cur;
        val_next = val_cur;
        delay_cnt_next = delay_cnt;
        I2C_EN = 0;
        I2C_START = 0;
        I2C_STOP = 0;
        tx_data = 8'h0;
        busy = 0;
        done = 0;
        case (cur)
            S_IDLE: begin
                if (start) begin
                    next = S_FETCH;
                end
            end
            S_FETCH: begin
                busy = 1;
                reg_next = rom_data[15:8];
                val_next = rom_data[7:0];
                next = S_CHECK;
            end

            S_CHECK: begin
                if (reg_cur == 8'hff && val_cur == 8'hff) begin
                    next = S_DONE;
                end else if (reg_cur == 8'hff) begin
                    delay_cnt_next = 0;
                    next = S_DELAY;
                end else begin
                    next = S_SEND_ADDR;
                end
            end

            S_DELAY: begin
                if (delay_cnt == DELAY_CYCLES - 1) begin
                    delay_cnt_next = 0;
                    next = S_NEXT;
                end else begin
                    delay_cnt_next = delay_cnt + 1;
                end
            end

            S_SEND_ADDR: begin
                I2C_EN = 1'b1;
                tx_data = OV7670_ADDR_WR;
                next = S_WAIT_ADDR;
            end

            S_WAIT_ADDR: begin
                I2C_EN = 1'b1;
                if (tx_ready) begin
                    next = S_SEND_REG;
                    tx_data = reg_cur;
                end
            end

            S_SEND_REG: begin
                I2C_EN = 1'b1;
                next   = S_WAIT_REG;
            end

            S_WAIT_REG: begin
                I2C_EN = 1'b1;
                if (tx_ready) begin
                    tx_data = val_cur;
                    next = S_SEND_VAL;
                end
            end

            S_SEND_VAL: begin
                I2C_EN = 1'b1;
                next   = S_WAIT_VAL;
            end

            S_WAIT_VAL: begin
                I2C_EN = 1'b1;
                if (tx_ready) begin
                    I2C_EN = 1;
                    I2C_STOP = 1;
                    next = S_ISSUE_STOP;
                end
            end

            S_ISSUE_STOP: begin
                next = S_WAIT_STOP;
            end
            S_WAIT_STOP: begin
                I2C_EN = 1'b1;
                if (tx_ready) begin
                    I2C_EN = 1'b0;
                    next = S_NEXT;
                end 
            end
            S_NEXT: begin
                next = S_FETCH;
            end

            S_DONE: begin
                done = 1;
            end

        endcase
    end

endmodule



// S_FETCH: begin
//                 reg_next = rom_data[15:8];
//                 val_next = rom_data[7:0];
//                 next = S_CHECK;
//             end
//             S_CHECK: begin
//                 if (reg_cur == 8'hff && val_cur == 8'hff) begin
//                     next = S_DONE;
//                 end else if (reg_cur == 8'hff) begin
//                     next = S_DELAY;
//                 end else begin
//                     next = S_SEND_ADDR;
//                 end
//             end

//             S_DELAY:begin
//                 if (delay_cnt == DELAY_CYCLES -1) begin
//                     delay_cnt = 0;
//                     next = S_DELAY;
//                 end else begin
//                     delay_cnt_next = delay_cnt;
//                 end
//             end

//             S_SEND_ADDR:begin
//                 busy = 1;
//                 I2C_EN = 1;
//                 tx_data = OV7670_ADDR_WR;
//                 next = S_WAIT_ADDR;
//             end

//             S_WAIT_ADDR:begin
//                 busy = 1;
//                 if (tx_ready) begin
//                     tx_data = reg_cur;
//                     next = S_SEND_REG;
//                 end
//             end
