module rtc_upcounter (
    input         clk,
    input         reset,
    input         wr,
    input  [25:0] initialvalue,
    output [ 5:0] o_sec,
    output [ 5:0] o_min,
    output [ 4:0] o_hour,
    output [ 4:0] o_day,
    output [ 3:0] o_month
);

    wire w_clk_sec;
    wire w_tick_sec, w_tick_min, w_tick_hour, w_tick_day;

    clkdiv_sec U_clkdiv_sec (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_clk_sec)
    );

    counter_sec U_counter_sec (
        .clk(clk),
        .clk_sec(w_clk_sec),
        .reset(reset),
        .wr(wr),
        .initialvalue(initialvalue),
        .o_tick_sec(w_tick_sec),
        .o_sec(o_sec)
    );

    counter_min U_counter_min (
        .clk(clk),
        .reset(reset),
        .i_tick_min(w_tick_sec),
        .wr(wr),
        .initialvalue(initialvalue),
        .o_tick_min(w_tick_min),
        .o_min(o_min)
    );

    counter_hour U_counter_hour (
        .clk(clk),
        .reset(reset),
        .i_tick_hour(w_tick_min),
        .wr(wr),
        .initialvalue(initialvalue),
        .o_tick_hour(w_tick_hour),
        .o_hour(o_hour)
    );

    counter_day U_counter_day (
        .clk(clk),
        .reset(reset),
        .i_tick_day(w_tick_hour),
        .wr(wr),
        .initialvalue(initialvalue),
        .o_tick_day(w_tick_day),
        .o_day(o_day)
    );

    counter_month U_counter_month (
        .clk(clk),
        .reset(reset),
        .i_tick_month(w_tick_day),
        .wr(wr),
        .initialvalue(initialvalue),
        .o_month(o_month)
    );

endmodule

module counter_sec (
    input             clk,
    input             clk_sec,
    input             reset,
    input             wr,
    input      [25:0] initialvalue,
    output reg        o_tick_sec,
    output     [ 5:0] o_sec
);

    reg [5:0] r_counter;
    assign o_sec = r_counter;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            o_tick_sec <= 0;
        end else begin
            if (wr) begin
                r_counter <= initialvalue[5:0];
            end else if (clk_sec) begin
                if (r_counter == 59) begin
                    r_counter  <= 0;
                    o_tick_sec <= 1;
                end else begin
                    r_counter <= r_counter + 1;
                end
            end else begin
                o_tick_sec <= 0;
            end
        end
    end

endmodule

module counter_min (
    input             clk,
    input             reset,
    input             i_tick_min,
    input             wr,
    input      [25:0] initialvalue,
    output reg        o_tick_min,
    output     [ 5:0] o_min
);

    reg [5:0] r_counter;
    assign o_min = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            o_tick_min <= 0;
        end else begin
            if (wr) begin
                r_counter <= initialvalue[11:6];
            end else if (i_tick_min) begin
                if (r_counter == 59) begin
                    r_counter  <= 0;
                    o_tick_min <= 1;
                end else begin
                    r_counter <= r_counter + 1;
                end
            end else begin
                o_tick_min <= 0;
            end
        end
    end
endmodule

module counter_hour (
    input             clk,
    input             reset,
    input             i_tick_hour,
    input             wr,
    input      [25:0] initialvalue,
    output reg        o_tick_hour,
    output     [ 4:0] o_hour
);

    reg [5:0] r_counter;
    assign o_hour = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter   <= 0;
            o_tick_hour <= 0;
        end else begin
            if (wr) begin
                r_counter <= initialvalue[16:12];
            end else if (i_tick_hour) begin
                if (r_counter == 23) begin
                    r_counter   <= 0;
                    o_tick_hour <= 1;
                end else begin
                    r_counter <= r_counter + 1;
                end
            end else begin
                o_tick_hour <= 0;
            end
        end
    end
endmodule

module counter_day (
    input             clk,
    input             reset,
    input             i_tick_day,
    input             wr,
    input      [25:0] initialvalue,
    output reg        o_tick_day,
    output     [ 4:0] o_day
);

    reg [5:0] r_counter;
    assign o_day = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            o_tick_day <= 0;
        end else begin
            if (wr) begin
                r_counter <= initialvalue[21:17];
            end else if (i_tick_day) begin
                if (r_counter == 30) begin
                    r_counter  <= 0;
                    o_tick_day <= 1;
                end else begin
                    r_counter <= r_counter + 1;
                end
            end else begin
                o_tick_day <= 0;
            end
        end
    end
endmodule

module counter_month (
    input         clk,
    input         reset,
    input         i_tick_month,
    input         wr,
    input  [25:0] initialvalue,
    output [ 3:0] o_month
);

    reg [5:0] r_counter;
    assign o_month = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            if (wr) begin
                r_counter <= initialvalue[25:22];
            end else if (i_tick_month) begin
                if (r_counter == 11) begin
                    r_counter <= 0;
                end else begin
                    r_counter <= r_counter + 1;
                end
            end
        end
    end
endmodule


module clkdiv_sec (
    input  clk,
    input  reset,
    output o_clk
);

    reg [26:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == 100_000_000 - 1) begin
//                 if (r_counter == 2 - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

endmodule
