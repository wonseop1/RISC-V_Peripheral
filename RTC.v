module RTC (
    input         clk,
    input         reset,
    input         wr,
    input         cs,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);
    wire [25:0] w_initialvalue;
    wire [5:0] w_o_sec, w_o_min;
    wire [4:0] w_o_hour, w_o_day;
    wire [3:0] w_o_month;
    wire w_wdataSignal;

    wire [11:0] w_min_sec;
    wire [10:0] w_hour_min;
    wire [8:0] w_month_day;

    RTCBus U_RTCBUS (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .cs(cs),
        .addr(addr),
        .wdata(wdata),
        .month_day(w_month_day),
        .hour_min(w_hour_min),
        .min_sec(w_min_sec),
        .rdata(rdata),
        .initialvalue(w_initialvalue),
        .wdataSignal(w_wdataSignal)

    );

    rtc_upcounter U_rtc_upcounter (
        .clk         (clk),
        .reset       (reset),
        .wr          (w_wdataSignal),
        .initialvalue(w_initialvalue),
        .o_sec       (w_o_sec),
        .o_min       (w_o_min),
        .o_hour      (w_o_hour),
        .o_day       (w_o_day),
        .o_month     (w_o_month)
    );

    T2S U_T2S (
        .sec(w_o_sec),
        .min(w_o_min),
        .hour(w_o_hour),
        .day(w_o_day),
        .month(w_o_month),
        .min_sec(w_min_sec),
        .hour_min(w_hour_min),
        .month_day(w_month_day)
    );

endmodule

module RTCBus (
    input        clk,
    input        reset,
    input        wr,
    input        cs,
    input [31:0] addr,
    input [31:0] wdata,

    input [8:0] month_day,
    input [10:0] hour_min,
    input [11:0] min_sec,
    output [31:0] rdata,
    output [25:0] initialvalue,
    output reg wdataSignal
);

    reg [31:0] regFile[0:3];
    reg [31:0] temp[0:2];



    // Custom Port Connection
    assign initialvalue = regFile[0][25:0];
    // assign month_day   = regFile[1][8:0];
    // assign hour_min  = regFile[2][10:0];
    // assign min_sec   = regFile[3][11:0];

    // Rdate Connection Port
    assign rdata = regFile[addr[3:2]];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regFile[0]  <= 0;
            wdataSignal <= 0;
        end else begin
            if (cs & wr) begin
                if (addr[3:2] == 2'b00) begin
                    regFile[0]  <= wdata;
                    wdataSignal <= 1;
                end else begin
                    wdataSignal <= 0;
                end
            end else begin
                wdataSignal <= 0;
            end
        end
    end

    always @(*) begin
        if (clk) begin
            temp[0] = {23'b0, month_day};
            temp[1] = {21'b0, hour_min};
            temp[2] = {20'b0, min_sec};
        end else begin
            temp[0] = temp[0];
            temp[1] = temp[1];
            temp[2] = temp[2];
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            regFile[1] <= 0;
            regFile[2] <= 0;
            regFile[3] <= 0;
        end else begin
            regFile[1] <= temp[0];
            regFile[2] <= temp[1];
            regFile[3] <= temp[2];
        end
    end


endmodule

module T2S (
    input  [ 5:0] sec,
    input  [ 5:0] min,
    input  [ 4:0] hour,
    input  [ 4:0] day,
    input  [ 3:0] month,
    output [11:0] min_sec,
    output [10:0] hour_min,
    output [ 9:0] month_day
);

    assign min_sec   = min * 100 + sec;
    assign hour_min  = hour * 100 + min;
    assign month_day = month * 100 + day;

endmodule
