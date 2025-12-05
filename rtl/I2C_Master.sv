`timescale 1ns / 1ps

module I2C_Master (
    // glob sig
    input  logic       clk,
    input  logic       reset,
    // interanl sig
    input  logic       I2C_EN,
    input  logic       I2C_START,
    input  logic       I2C_STOP,
    input  logic [7:0] tx_data,
    input  logic       rd_ack,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    // external sig
    output logic       scl,
    inout  logic       sda
);

    typedef enum {
        IDLE,
        START1,
        START2,
        DATA1,
        DATA2,
        DATA3,
        DATA4,
        READ1,
        READ2,
        READ3,
        READ4,
        HOLD,
        ACK1_WRITE,
        ACK2_WRITE,
        ACK3_WRITE,
        ACK4_WRITE,
        ACK1_READ,
        ACK2_READ,
        ACK3_READ,
        ACK4_READ,
        STOP1,
        STOP2
    } state_e;
    state_e cur, next;

    // logic level 
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [8:0] clk_cnt_reg, clk_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic out_data;
    logic sda_out_en;

    // assign level
    assign rx_data = rx_data_reg;
    assign sda = sda_out_en ? out_data : 1'bz;  // if 1 -> data write, if 0-> data read


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cur <= IDLE;
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            clk_cnt_reg <= 0;
            bit_cnt_reg <= 0;
        end else begin
            cur <= next;
            tx_data_reg <= tx_data_next;
            rx_data_reg <= rx_data_next;
            clk_cnt_reg <= clk_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end

    always_comb begin
        // state
        next = cur;
        // data & cnt buffer
        tx_data_next = tx_data_reg;
        rx_data_next = rx_data_reg;
        clk_cnt_next = clk_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        // output & state flag
        sda_out_en = 1'b1;
        out_data = 1'b1;
        scl = 1'b1;
        tx_done = 1'b0;
        tx_ready = 1'b0;
        rx_done = 1'b0;
        case (cur)
            IDLE: begin
                tx_ready = 1;
                tx_data_next = tx_data;
                sda_out_en = 1;
                if (I2C_EN) begin
                    next = START1;
                end
            end

            HOLD: begin
                tx_ready = 1;
                sda_out_en = 1;
                rx_data_next = 0;
                if (I2C_EN) begin
                    if (I2C_START == 0 && I2C_STOP == 0) begin
                        tx_data_next = tx_data;
                        // out_data = tx_data_next[7];
                        scl = 1'b0;
                        next = DATA1;
                    end else if (I2C_START == 0 && I2C_STOP == 1) begin
                        out_data = 0;
                        scl = 1;
                        next = STOP1;
                    end else if (I2C_START == 1 && I2C_STOP == 0) begin
                        out_data = 1;
                        scl = 1'b1;
                        next = START1;
                    end else if (I2C_START == 1 && I2C_STOP == 1) begin
                        sda_out_en = 1'b0;
                        scl = 1'b0;
                        next = READ1;
                    end
                end
            end

            START1: begin
                sda_out_en = 1;
                out_data = 1'b0;
                scl = 1'b1;
                if (I2C_EN) begin
                    if (clk_cnt_reg == 499) begin
                        clk_cnt_next = 0;
                        next = START2;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end

            end

            START2: begin
                sda_out_en = 1;
                out_data = 1'b0;
                scl = 1'b0;
                if (I2C_EN) begin
                    if (clk_cnt_reg == 499) begin
                        clk_cnt_next = 0;
                        next = DATA1;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            DATA1: begin
                sda_out_en = 1;
                scl = 1'b0;
                out_data = tx_data_reg[7];
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        clk_cnt_next = 0;
                        next = DATA2;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            DATA2: begin
                sda_out_en = 1;
                scl = 1'b1;
                out_data = tx_data_reg[7];
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        clk_cnt_next = 0;
                        next = DATA3;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end

            end

            DATA3: begin
                sda_out_en = 1;
                scl = 1'b1;
                out_data = tx_data_reg[7];
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        clk_cnt_next = 0;
                        next = DATA4;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end

            end
            DATA4: begin
                sda_out_en = 1;
                scl = 1'b0;
                out_data = tx_data_reg[7];
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        if (bit_cnt_reg == 7) begin
                            tx_done = 1'b1;
                            clk_cnt_next = 0;
                            bit_cnt_next = 0;
                            next = ACK1_WRITE;
                        end else begin
                            next = DATA1;
                            clk_cnt_next = 0;
                            tx_data_next = {tx_data_reg[6:0], 1'b0};
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            READ1: begin
                sda_out_en = 0;
                scl = 1'b0;
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        rx_data_next = {rx_data_reg[6:0], {sda}};
                        clk_cnt_next = 0;
                        next = READ2;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            READ2: begin
                sda_out_en = 0;
                scl = 1'b1;
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        clk_cnt_next = 0;
                        next = READ3;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            READ3: begin
                sda_out_en = 0;
                scl = 1'b1;
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        clk_cnt_next = 0;
                        next = READ4;
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            READ4: begin
                sda_out_en = 0;
                scl = 1'b0;
                if (I2C_EN) begin
                    if (clk_cnt_reg == 249) begin
                        if (bit_cnt_reg == 7) begin
                            clk_cnt_next = 0;
                            rx_done = 1'b1;
                            bit_cnt_next = 0;
                            next = ACK1_READ;
                        end else begin
                            clk_cnt_next = 0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            next = READ1;
                        end
                    end else begin
                        clk_cnt_next = clk_cnt_reg + 1;
                    end
                end
            end

            ACK1_WRITE: begin
                sda_out_en = 0;
                scl = 1'b0;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = ACK2_WRITE;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end


            ACK2_WRITE: begin
                sda_out_en = 0;
                scl = 1'b1;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = ACK3_WRITE;
                    // if (sda == 0) begin
                    //     clk_cnt_next = 0;
                    //     next = ACK3_WRITE;
                    // end else begin
                    //     next = IDLE;
                    // end
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end


            ACK3_WRITE: begin
                sda_out_en = 0;
                scl = 1'b1;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = ACK4_WRITE;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end

            ACK4_WRITE: begin
                sda_out_en = 0;
                scl = 1'b0;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = HOLD;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end

            ACK1_READ: begin
                sda_out_en = 1;
                out_data = rd_ack;
                scl = 1'b0;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = ACK2_READ;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end


            ACK2_READ: begin
                sda_out_en = 1;
                out_data = rd_ack;
                scl = 1'b1;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = ACK3_READ;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end


            ACK3_READ: begin
                sda_out_en = 1;
                out_data = rd_ack;
                scl = 1'b1;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = ACK4_READ;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end

            ACK4_READ: begin
                sda_out_en = 0;
                scl = 1'b0;
                if (clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    next = HOLD;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end


            STOP1: begin
                sda_out_en = 1;
                out_data = 0;
                scl = 1;
                if (clk_cnt_reg == 499) begin
                    clk_cnt_next = 0;
                    next = STOP2;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end

            STOP2: begin
                sda_out_en = 1;
                out_data = 1;
                scl = 1;
                if (clk_cnt_reg == 499) begin
                    clk_cnt_next = 0;
                    next = IDLE;
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end

        endcase
    end
endmodule
