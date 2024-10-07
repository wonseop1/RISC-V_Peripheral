`timescale 1ns / 1ps

module FND_ph(
    input         clk,
    input         reset,
    input         cs,
    input         wr,//write =1
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    output [3:0] fndCom,
    output [7:0] fndFont

);

wire [13:0] w_fdr;
wire w_fcr;


Fnd_bus U_Fnd_bus(
    .clk(clk),
    .reset(reset),
    .cs(cs),
    .wr(wr),//write =1
    .addr(addr),
    .wdata(wdata),
    .fcr(w_fcr),
    .fdr(w_fdr),
    .rdata(rdata)
);

FndController U_FndController(
    .clk(clk),
    .reset(reset),
    .fcr(w_fcr),
    .fdr(w_fdr),
    //
    .fndCom(fndCom),
    .fndFont(fndFont)
);

endmodule


module Fnd_bus(
    input         clk,
    input         reset,
    input         cs,
    input         wr,//write =1
    input  [31:0] addr,
    input  [31:0] wdata,
    //output [3:0] fcr,
    output fcr,
    output [13:0] fdr,
    output [31:0] rdata
);

reg [31:0] regFnd [0:1];

//write
always @(posedge clk, posedge reset) begin
    if(reset) begin
        regFnd[0] <= 0;
        regFnd[1] <= 0;
    end else begin
        if(cs & wr) begin
            regFnd[addr[2]] <= wdata;
        end 
    end
end

// custom port
//assign fcr = regFnd[0][3:0];
//assign fdr = regFnd[1][3:0];
assign fcr = regFnd[0][0];
assign fdr = regFnd[1][13:0];

 // data connection port
assign rdata = regFnd[addr[2]];

endmodule



module FndController(
    input clk,
    input reset,
    //input [3:0] fcr,
    input fcr,
    input [13:0] fdr,
    
    output [3:0] fndCom,
    output [7:0] fndFont
);

wire w_clk_1khz;
wire [1:0] w_select;
wire [3:0] w_digit, w_dig_1,w_dig_10,w_dig_100,w_dig_1000;

//assign fndCom = ~fcr;

BCD2SEG U_BCD2SEG(
    .din(w_digit),

    .seg_d(fndFont)
);

decorder_2x4 U_decorder_2x4(
    .x(w_select),
    .en(fcr),
    //
    .y(fndCom)
);

mux_4x1 U_mux_4x1(
    .sel(w_select),
    .x0(w_dig_1),
    .x1(w_dig_10),
    .x2(w_dig_100),
    .x3(w_dig_1000),
    //
    .y(w_digit)
);

digitSplitter U_digitSplitter(
    .x(fdr),
    //
    .dig_1(w_dig_1),
    .dig_10(w_dig_10),
    .dig_100(w_dig_100),
    .dig_1000(w_dig_1000)
);

counter U_counter(
    .clk(w_clk_1khz),
    .reset(reset),
    //
    .count(w_select)
);

clkDiv U_clkDiv(
    .clk(clk),
    .reset(reset),
    //
    .o_clk(w_clk_1khz)
);

endmodule

module BCD2SEG (
    input [3:0] din,

    output reg [7:0] seg_d
);

    always @(din) begin
        case (din)
            4'h0: seg_d = ~8'h3f;
            4'h1: seg_d = ~8'h06;
            4'h2: seg_d = ~8'h5b;
            4'h3: seg_d = ~8'h4f;
            4'h4: seg_d = ~8'h66;
            4'h5: seg_d = ~8'h6d;
            4'h6: seg_d = ~8'h7d;
            4'h7: seg_d = ~8'h27;
            4'h8: seg_d = ~8'h7f;
            4'h9: seg_d = ~8'h6f;
            4'ha: seg_d = ~8'h5f;
            4'hb: seg_d = ~8'h7c;
            4'hc: seg_d = ~8'h58;
            4'hd: seg_d = ~8'h5e;
            4'he: seg_d = ~8'h7b;
            4'hf: seg_d = ~8'h71;
        endcase
    end

endmodule


module digitSplitter (
    input  [13:0] x,
    output [ 3:0] dig_1,
    output [ 3:0] dig_10,
    output [ 3:0] dig_100,
    output [ 3:0] dig_1000
);

    assign dig_1    = x % 10;
    assign dig_10   = x /10 % 10;
    assign dig_100  = x /100 % 10;
    assign dig_1000 = x /1000 % 10;

endmodule

module decorder_2x4 (
    input [1:0] x,
    input en,
    output reg [3:0] y
);
    always @(x) begin
        if(en) begin
            case (x)
            2'b00: y = 4'b1110;
            2'b01: y = 4'b1101;
            2'b10: y = 4'b1011;
            2'b11: y = 4'b0111;
        endcase
        end else begin
            y = 4'b1111;
        end
    end

endmodule

module mux_4x1 (
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);

    always @(*) begin
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end

endmodule

module counter (
    input clk,
    input reset,
    output [1:0] count
);

    reg [1:0] r_counter;
    assign count = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            if (r_counter == 3) begin
                r_counter <= 0;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
    end

endmodule

module clkDiv (
    input  clk,
    input  reset,
    output o_clk
);
    reg [16:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

endmodule
