`timescale 1ns / 1ps
module uart(
    // global signal
    input clk,
    input reset,
    // transmitter signal
    input start,
    input [7:0] tx_data,
    output tx_done,
    output tx,
    // receiver signal
    input rx,
    output [7:0] rx_data,
    output rx_done
);

wire w_br_tick;

baudrate_gen u_baudrate_gen(
    .clk(clk),
    .reset(reset),
    .br_tick(w_br_tick)
);

transmitter u_transmitter(
    .clk(clk),
    .reset(reset),
    .br_tick(w_br_tick),
    .start(start),
    .tx_data(tx_data),
    .tx_done(tx_done),
    .tx(tx)
);

receiver u_receiver(
    .clk(clk),
    .reset(reset),
    .br_tick(w_br_tick),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .rx(rx)
);

endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////
module baudrate_gen (
    input clk,
    input reset,
    output br_tick
);

    reg [$clog2(100_000_000/9600/16)-1 : 0] r_counter;
    reg r_tick;
    
    assign br_tick = r_tick;

always@(posedge clk, posedge reset)
begin
    if (reset)
    begin
        r_counter <= 0;
        r_tick <= 1'b0;
    end
    else
    begin
        //if (r_counter == 2 - 1)  // for simulation
        if (r_counter == 100_000_000/9600/16 - 1)
        begin
            r_counter <= 0;
            r_tick <= 1'b1;
        end
        else
        begin
            r_counter <= r_counter + 1;
            r_tick <= 1'b0;
        end
    end
end
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////
module transmitter (
    input clk,
    input reset,
    input br_tick,
    input start,
    input [7:0] tx_data,
    output tx_done,
    output tx
);
    
    parameter IDLE_S = 4'd0, START_S = 4'd1, DATA_S = 4'd2,STOP_S = 4'd3;

    reg [3:0] state, next_state;
    reg tx_reg, tx_next, tx_done_reg, tx_done_next;
    reg [7:0] temp_data_reg, temp_data_next;
    reg [3:0] tick_cnt_reg, tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;

    // output combinational logic
    assign tx = tx_reg;
    assign tx_done = tx_done_reg;

    // state, var register
    always@ (posedge clk, posedge reset)
    begin
        if (reset)
        begin
            state <= IDLE_S;
            tx_reg <= 1'b0;  
            tx_done_reg <= 1'b0;
            temp_data_reg <= 0;
            tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
        end
        else
        begin
            state <= next_state;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
            temp_data_reg <= temp_data_next;
            tick_cnt_reg <= tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end

    // next state combinational logic
    always@ (*)
    begin
        next_state = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        temp_data_next = temp_data_reg;
        tick_cnt_next = tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        case (state)
            IDLE_S :
            begin
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                if (start == 1'b1)
                begin
                    temp_data_next = tx_data; // latching
                    next_state = START_S;
                    tick_cnt_next = 0;
                    bit_cnt_next = 0;
                end
            end
            START_S :
            begin
                tx_next = 1'b0;
                if (br_tick == 1'b1)
                begin
                    if (tick_cnt_reg == 15)
                    begin
                        next_state = DATA_S;
                        tick_cnt_next = 0;
                    end
                    else
                    begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_S : begin
                tx_next = temp_data_reg[0];
                if (br_tick == 1'b1)begin
                    if (tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            next_state = STOP_S;
                            bit_cnt_next = 0;
                        end
                        else begin
                            temp_data_next = {1'b0, temp_data_reg[7:1]};
                            bit_cnt_next = bit_cnt_reg + 1;
                        end 
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            STOP_S : begin
                tx_next = 1'b1;
                if (br_tick == 1'b1) begin
                    if (tick_cnt_reg == 15) begin
                        tx_done_next = 1'b1;
                        next_state = IDLE_S;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////
module receiver (
    input clk,
    input reset,
    input br_tick,
    output [7:0] rx_data,
    output rx_done,
    input rx
);

    parameter IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    
    reg [1:0] state, next_state;
    reg [7:0] rx_data_reg, rx_data_next;
    reg rx_done_reg, rx_done_next;
    reg [3:0] sample_cnt_reg, sample_cnt_next;
    reg [15:0] sample_bit_reg, sample_bit_next;
    reg [3:0] bit_cnt_reg, bit_cnt_next;  // 8 count


    // output combinational logic
    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;

    // state register
    always @(posedge clk, posedge reset) begin
        if(reset) begin 
            state <= IDLE;
            rx_data_reg <= 0;
            rx_done_reg <= 1'b0;
            sample_cnt_reg <= 0;
            sample_bit_reg <= 0;
            bit_cnt_reg <= 0;
        end
        else begin
            state <= next_state;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
            sample_cnt_reg <= sample_cnt_next;
            sample_bit_reg <= sample_bit_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end

    // next state combinational loic
    always @(*) begin
        next_state = state;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;
        sample_cnt_next = sample_cnt_reg;
        sample_bit_next = sample_bit_reg;
        bit_cnt_next = bit_cnt_reg;

        case(state)
            IDLE: begin 
                rx_done_next = 1'b0;
                if(rx==0) begin
                    sample_cnt_next = 0;
                    next_state = START;
                end
                else begin
                    next_state = IDLE;
                end
            end

            START: begin
                rx_data_next = 0;
                if(br_tick) begin 
                    if(sample_cnt_reg == 15) begin 
                        sample_cnt_next = 0;
                        next_state = DATA;
                    end
                    else begin 
                        sample_cnt_next = sample_cnt_reg + 1;
                        next_state = START;
                    end
                end
            end

            DATA: begin
                if(br_tick) begin
                    sample_bit_next = {rx, sample_bit_reg[15:1]};
                    if(sample_cnt_reg == 15) begin
                        sample_cnt_next = 0;
                        rx_data_next = {sample_bit_reg[7], rx_data_reg[7:1]};
                        if(bit_cnt_reg == 7) begin 
                            bit_cnt_next = 0;
                            next_state = STOP;
                        end
                        else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end
                    else begin
                        sample_cnt_next = sample_cnt_reg + 1;
                    end
                end
            end

            STOP: begin 
                if(br_tick) begin 
                    if(sample_cnt_reg == 15) begin 
                        sample_cnt_next = 0;
                        rx_done_next = 1'b1;
                        next_state = IDLE;
                    end
                    else begin
                        sample_cnt_next = sample_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule