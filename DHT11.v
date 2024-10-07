`timescale 1ns / 1ps

module top_dht11 (
    input clk,
    input rst,
    //input start,  // for simulation
    inout dht_signal,
    output [7:0] hum_high,
    output [7:0] hum_low,
    output [7:0] tem_high,
    output [7:0] tem_low,
    output [7:0] checksum,
    output state_done
);

    wire w_tick_10khz, w_tick_1Mhz;

    DHT11 u_dht11_fsm (
        .clk       (clk),
        .rst       (rst),
        //.start     (start),         //for simulation
        .tick_100us(w_tick_10khz),
        .tick_1us  (w_tick_1Mhz),
        .signal    (dht_signal),
        .hum_high  (hum_high),
        .hum_low   (hum_low),
        .tem_high  (tem_high),
        .tem_low   (tem_low),
        .checksum  (checksum),
        .dht_tx_signal (state_done)
    );

    clk_div #(
        .HZ(1000_000)
        //.HZ(100_000_00)  //for simulation
    ) u_clk_1Mhz (
        .clk  (clk),
        .rst  (rst),
        .o_clk(w_tick_1Mhz)
    );

    clk_div #(
        .HZ(10000)
        //.HZ(100_000_0)  //for simulation
    ) u_clk_10khz (
        .clk  (clk),
        .rst  (rst),
        .o_clk(w_tick_10khz)
    );


endmodule

module DHT11 (
    input clk,
    input rst,
    //input start,  //for simulation
    input tick_100us,
    input tick_1us,
    inout signal,
    output [7:0] hum_high,
    output [7:0] hum_low,
    output [7:0] tem_high,
    output [7:0] tem_low,
    output [7:0] checksum,
    output dht_tx_signal
);

    parameter IDLE = 3'd0, START_LOW = 3'd1, START_HIGH = 3'd2, READY_LOW = 3'd3, READY_HIGH = 3'd4, DATA_LOW = 3'd5, DATA_HIGH = 3'd6, DATA_OUT=3'd7;

    reg dht11_sig0, dht11_sig1;
    reg [2:0] curr_state, next_state;  //data state
    reg [20:0] cnt_1us_reg, cnt_1us_next;  //for us count
    reg [20:0] cnt_100us_reg, cnt_100us_next;  // for ms count
    reg data_signal_reg, data_signal_next;  //output DHT11 signal
    reg [5:0] bit_cnt_reg, bit_cnt_next;  //data 40bits count
    reg [39:0] dht11_data_next, dht11_data_reg;  //temp data
    reg [39:0] temp_data_reg, temp_data_next;
    wire [7:0] humidity_high, humidity_low, temperature_high, temperature_low, parity;

    reg dht_tx_signal_reg, dht_tx_signal_next;

    reg sig_inout,sig_inout_next;

    assign hum_high = humidity_high;
    assign hum_low  = humidity_low;
    assign tem_high = temperature_high;
    assign tem_low  = temperature_low;
    assign checksum = parity;
    assign dht_tx_signal = dht_tx_signal_reg;
    // ila_0 u_ila (
    //     .clk(clk),
    //     .probe0(signal),
    //     .probe1(curr_state),
    //     .probe2(cnt_1us_reg),
    //     .probe3(cnt_100us_reg),
    //     .probe4(bit_cnt_reg),
    //     .probe5(dht11_data_reg),
    //     .probe6(temp_data),
    //     .probe7(hum_high)
    // );


    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            curr_state <= IDLE;
            cnt_1us_reg <= 0;
            cnt_100us_reg <= 0;
            data_signal_reg <= 1'bz;
            bit_cnt_reg <= 0;
            dht11_data_reg <= 0;
            temp_data_reg <= 0;
            sig_inout <= 0;
            dht_tx_signal_reg <= 0; //for tx
        end else begin
            curr_state <= next_state;
            cnt_1us_reg <= cnt_1us_next;
            cnt_100us_reg <= cnt_100us_next;
            data_signal_reg <= data_signal_next;
            bit_cnt_reg <= bit_cnt_next;
            dht11_data_reg <= dht11_data_next;
            temp_data_reg <= temp_data_next;
            sig_inout <= sig_inout_next;
            dht_tx_signal_reg <= dht_tx_signal_next; //for tx
        end
    end

    always @(*) begin
        temp_data_next = temp_data_reg;
        next_state = curr_state;
        cnt_100us_next = cnt_100us_reg;
        cnt_1us_next = cnt_1us_reg;
        data_signal_next = data_signal_reg;
        bit_cnt_next = bit_cnt_reg;
        dht11_data_next = dht11_data_reg;
        sig_inout_next = sig_inout;
        dht_tx_signal_next = dht_tx_signal_reg;
        case (curr_state)
            IDLE: begin
                dht_tx_signal_next = 1'b0;
                //data_signal_next = 1'bz;
                if (tick_100us) begin
                    cnt_100us_next = cnt_100us_reg + 1;
                end
                if(cnt_100us_reg == 49500) begin
                    sig_inout_next = 1;
                    data_signal_next = 1;
                end
                else if (cnt_100us_reg >= 50_000) begin
                    //if (cnt_100us_reg >= 5) begin  //for simulation
                    //if (start) begin  //for simulation
                    next_state = START_LOW;
                    cnt_100us_next = 0;
                end
                
            end
            START_LOW: begin
                sig_inout_next = 1;
                data_signal_next = 1'b0;
                if (tick_100us) begin
                    cnt_100us_next = cnt_100us_reg + 1;
                end
                if (cnt_100us_reg >= 200) begin
                    //if (cnt_100us_reg >= 2) begin  //for simulation
                    next_state   = START_HIGH;
                    cnt_1us_next = 0;
                end
            end
            START_HIGH: begin            //START HIGH signal 20~40us                        
                if (tick_1us) begin
                    cnt_1us_next = cnt_1us_reg + 1;
                end
                // if (cnt_1us_reg < 25) begin
                //     sig_inout_next = 0;
                if (cnt_1us_reg < 40) begin
                    sig_inout_next = 0;
                    //data_signal_next = 1'bz;
                    //if (dht11_sig0 == 0) begin  //for simulation
                    if (sig_fedge) begin
                        next_state   = READY_LOW;
                        cnt_1us_next = 0;
                    end
                end else begin
                    next_state = IDLE;  //error process
                    cnt_1us_next = 0;
                    cnt_100us_next = 0;
                end
            end
            READY_LOW: begin  //READY Low signal 80us
                sig_inout_next = 0;
                //data_signal_next = 1'bz;
                if (tick_1us) begin
                    cnt_1us_next = cnt_1us_reg + 1;
                end
                if (cnt_1us_reg <= 100) begin
                    if (sig_redge) begin
                        next_state   = READY_HIGH;
                        cnt_1us_next = 0;
                    end
                end else begin
                    next_state = IDLE;  //error process
                    cnt_1us_next = 0;
                    cnt_100us_next = 0;
                end
            end
            READY_HIGH: begin  //READY HIGH signal 80us
                sig_inout_next = 0;
                //data_signal_next = 1'bz;
                if (tick_1us) begin
                    cnt_1us_next = cnt_1us_reg + 1;
                end
                if (cnt_1us_reg <= 100) begin
                    if (sig_fedge) begin
                        next_state   = DATA_LOW;
                        cnt_1us_next = 0;
                        bit_cnt_next = 0;
                    end
                end else begin
                    next_state = IDLE;  //error process
                    cnt_1us_next = 0;
                    cnt_100us_next = 0;
                end
            end
            DATA_LOW: begin  //DATA Low time
                sig_inout_next = 0;
                //data_signal_next = 1'bz;
                if (tick_1us) begin
                    cnt_1us_next = cnt_1us_reg + 1;
                end
                if (cnt_1us_reg < 55) begin
                    if (sig_redge) begin
                        next_state   = DATA_HIGH;
                        cnt_1us_next = 0;
                    end
                end else begin
                    next_state = IDLE;  //error process
                    cnt_1us_next = 0;
                    cnt_100us_next = 0;
                end
            end
            DATA_HIGH: begin //DATA High time => 26~28us : '0' , 70us : '1' + data bits count
                sig_inout_next = 0;
                //data_signal_next = 1'bz;
                if (tick_1us) begin
                    cnt_1us_next = cnt_1us_reg + 1;
                end
                if (cnt_1us_reg < 80) begin
                    if (sig_fedge) begin
                        bit_cnt_next = bit_cnt_reg + 1;
                        if (cnt_1us_reg < 50)
                            dht11_data_next = {dht11_data_reg[38:0], 1'b0};
                        else begin
                            dht11_data_next = {dht11_data_reg[38:0], 1'b1};
                        end
                        if (bit_cnt_reg == 39) begin
                            next_state = DATA_OUT;
                        end else begin
                            next_state   = DATA_LOW;
                            cnt_1us_next = 0;
                        end
                    end
                end else begin
                    next_state = IDLE;  //error process
                    cnt_1us_next = 0;
                    cnt_100us_next = 0;
                end

            end
            DATA_OUT: begin
                sig_inout_next  = 0;
                temp_data_next  = dht11_data_reg;
                next_state = IDLE;
                dht_tx_signal_next = 1'b1;
            end
        endcase
    end

    assign humidity_high    = temp_data_reg[39:32];
    assign humidity_low     = temp_data_reg[31:24];
    assign temperature_high = temp_data_reg[23:16];
    assign temperature_low  = temp_data_reg[15:8];
    assign parity           = temp_data_reg[7:0];

    //dht input signal register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dht11_sig0 <= 0;
        end else begin
            dht11_sig1 <= dht11_sig0;
            dht11_sig0 <= signal;
        end
    end

    assign sig_fedge = ~dht11_sig0 & dht11_sig1;  //falling edge
    assign sig_redge = dht11_sig0 & ~dht11_sig1;  //rising edge
    //assign signal = data_signal_reg;
    assign signal = (!sig_inout) ? 1'bz : data_signal_reg;
endmodule


module clk_div #(
    parameter HZ = 100
) (
    input  clk,
    input  rst,
    output o_clk
);

    reg [$clog2(100_000_000/HZ) - 1 : 0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            if (r_counter == 100_000_000 / HZ - 1) begin
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 0;
            end
        end
    end

endmodule
