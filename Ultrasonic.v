`timescale 1ns / 1ps

module Ultrasonic (
    input         clk,
    input         reset,
    input         wr,
    input         cs,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    input         echo,
    output        trig
);

    wire [13:0] echo_cnt_out;
    wire        trig_ip;
    wire        trig_control;


    Ultrasonic_ip U_Ultrasonic_ip (
        .clk         (clk),
        .reset       (reset),
        .echo        (echo),
        .trig        (trig_ip),
        .echo_cnt_out(echo_cnt_out)
    );


    Ultrasonic_BUS U_Ultrasonic_BUS (
        .clk         (clk),
        .reset       (reset),
        .wr          (wr),
        .cs          (cs),
        .addr        (addr),
        .wdata       (wdata),
        .rdata       (rdata),
        .echo_cnt_out(echo_cnt_out),
        .trig_control(trig_control)
    );


    assign trig = trig_ip&trig_control;

endmodule


module Ultrasonic_BUS (
    input clk,
    input reset,
    input wr,
    input cs,
    input [31:0] addr,
    input [31:0] wdata,
    output [31:0] rdata,
    input [13:0] echo_cnt_out,
    output reg trig_control

);

    reg [31:0] regFile[0:1]; // 0번: on/off 제어, 1번: 거리 데이터 저장
    reg [31:0] temp_rdata;   // 읽기 데이터 저장을 위한 임시 변수

    // 데이터 읽기 작업 및 외부에 rdata 연결
    assign rdata = temp_rdata;

    // 데이터 업데이트 블록
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regFile[0] <= 0;  // on/off 제어 초기화
            regFile[1] <= 0;  // 거리 데이터 초기화
            trig_control <= 0; // 초기화 시 제어 신호도 0으로 설정
        end else begin
            if (cs & wr) begin
                regFile[addr[2]] <= wdata;  // 쓰기 작업
            end else if (cs & !wr) begin
                if (addr == 32'h4000_0504) begin
                    regFile[1] <= {18'b0, echo_cnt_out};  // 거리 데이터 저장
                end
            end
            trig_control <= regFile[0][0]; // regFile[0][0]으로 트리거 제어
        end
    end

    // rdata에 출력할 값을 결정
    always @(*) begin
        temp_rdata = regFile[addr[2]];
    end

endmodule


module Ultrasonic_ip (
    input clk,
    input reset,
    input echo,

    output trig,
    output [13:0] echo_cnt_out
);

    wire w_tick_1us;
    wire w_tick_15us;
    wire w_echo_cnt_reset;
    wire [19:0] w_echo_cnt;

    // 100ms period & 15us trigger
    clk_div_trigger U_Clk_div_trigger (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_tick_15us)
    );

    // Make tick (1us)
    clk_div2 #(
        .HZ(1_000_000)  // 1us
    ) ECHO_1us (
        .clk  (clk),
        .reset(reset),

        .o_clk(w_tick_1us)
    );

    // Count Echo (cm)
    Echo_Counter ECHO_CNT (
        .clk           (clk),
        .tick_1us      (w_tick_1us),
        .reset         (reset),
        .echo_cnt_en   (w_echo_cnt_en),
        .echo_cnt_reset(w_echo_cnt_reset),
        .count         (w_echo_cnt)
    );

    //Ultra_Sonic FSM
    ultra_sonic_fsm U_ultra_sonic_fsm (
        .clk     (clk),
        .reset   (reset),
        .trig    (w_tick_15us),
        .echo    (echo),         // echo pin
        .echo_cnt(w_echo_cnt),

        .tick_15us     (trig),              // trig pin
        .echo_cnt_en   (w_echo_cnt_en),
        .echo_cnt_reset(w_echo_cnt_reset),
        .echo_cnt_out  (echo_cnt_out)
    );
endmodule

// clock divder(100ms) for Ultra_Sonic trigger signal
module clk_div_trigger (
    input  clk,
    input  reset,
    output o_clk
);
    reg [$clog2(100_000_000/5)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            if (r_counter >= 100_000_000 / 5 - 1) begin
                r_counter <= 0;
                r_clk <= 1'b0;
            end else if (r_counter >= 100_000_000 / 5 - 1500) begin  // 15us
                r_clk <= 1'b1;
                r_counter <= r_counter + 1;
            end else begin
                r_clk <= 1'b0;
                r_counter <= r_counter + 1;
            end
        end
    end

endmodule

// clock divider
module clk_div2 #(
    parameter HZ = 1000
) (
    input  clk,
    input  reset,
    output o_clk
);
    reg [$clog2(100_000_000/HZ)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            if (r_counter == 100_000_000 / HZ - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

endmodule

// Echo Pulse Counter
module Echo_Counter (
    input clk,
    input tick_1us,
    input reset,
    input echo_cnt_en,
    input echo_cnt_reset,

    output [19:0] count
);
    reg [15:0] r_counter;
    reg [15:0] cnt_reg;

    assign count = cnt_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            cnt_reg   <= 0;
        end else begin
            cnt_reg <= r_counter / 58;
            if (echo_cnt_en) begin
                if (tick_1us) begin
                    if (r_counter == 36_200 - 1) begin  //580000
                        r_counter <= 0;
                    end else begin
                        r_counter <= r_counter + 1;
                    end
                end
            end else if (echo_cnt_reset) begin
                r_counter <= 0;
            end
        end
    end

endmodule

module ultra_sonic_fsm (
    input        clk,
    input        reset,
    input        trig,     // 15us trigger
    input        echo,     // echo pin
    input [19:0] echo_cnt,

    output        tick_15us,       // trig pin
    output        echo_cnt_en,     // for echo cnt
    output        echo_cnt_reset,  // for echo cnt reset
    output [13:0] echo_cnt_out
);

    parameter IDLE = 2'd0, WAIT = 2'd1, CHECK = 2'd2;

    wire trig_edge_fall;  // trigger falling edge

    reg [1:0] state, next_state;
    reg trig_pl0, trig_pl1;  // for edge detect
    reg [13:0] echo_cnt_reg, echo_cnt_next;
    reg echo_cnt_reset_reg, echo_cnt_reset_next;

    // output state combinational logic
    assign trig_edge_fall = (trig_pl1 & ~trig_pl0);     // trigger falling edge
    assign tick_15us = trig;    // wire trigger
    assign echo_cnt_en = (state==CHECK) ? 1'b1: 1'b0;
    assign echo_cnt_reset = echo_cnt_reset_reg;
    assign echo_cnt_out = echo_cnt_reg;


    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            trig_pl0 <= 1'b0;
            trig_pl1 <= 1'b0;
            echo_cnt_reg <= 0;
            echo_cnt_reset_reg <= 1'b0;
        end else begin
            state <= next_state;
            trig_pl0 <= trig;
            trig_pl1 <= trig_pl0;
            echo_cnt_reg <= echo_cnt_next;
            echo_cnt_reset_reg <= echo_cnt_reset_next;
        end
    end


    // next state combinational logic
    always @(*) begin
        next_state = state;
        echo_cnt_next = echo_cnt_reg;
        echo_cnt_reset_next = echo_cnt_reset_reg;
        case (state)
            IDLE: begin
                if (trig_edge_fall) begin  // trigger falling edge
                    next_state = WAIT;
                    echo_cnt_reset_next = 1'b1;     // echo counter reset
                end else begin
                    next_state = IDLE;
                end
            end
            WAIT: begin
                if (echo) begin  // echo = 1
                    next_state = CHECK;
                    echo_cnt_reset_next = 1'b0;
                end else begin
                    next_state = WAIT;
                end
            end
            CHECK: begin
                if (~echo) begin  // echo = 0
                    next_state = IDLE;
                    echo_cnt_next = echo_cnt;
                end else begin
                    next_state = CHECK;
                end
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
