`timescale 1ns / 1ps

module GPI(
    input         clk,
    input         reset,
    input         cs,
    input         wr,
    input         addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    input  [ 7:0] gpi
    );
    
    reg [31:0] regGpi; //idr
    reg [31:0] temp;

    always @(*) begin
        if(clk) temp = {24'b0,gpi};
        else temp = temp;
    end

    always @(posedge clk , posedge reset) begin
        if(reset) begin
            regGpi <= 0;
        end
        else begin
            regGpi <= temp;
        end
    end

    assign rdata = regGpi;

endmodule
