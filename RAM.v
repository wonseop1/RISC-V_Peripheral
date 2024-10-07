`timescale 1ns / 1ps
`include "defines.v"

module RAM (
    input             clk,
    input             cs,
    input             we,
    input      [ 7:0] addr,
    input      [ 1:0] BHW,
    input      [31:0] wdata,
    output     [31:0] rdata
    // output reg [31:0] rdata
);
    reg [31:0] ram[0:2**6-1];

    integer i;
    initial begin
        ram[0] = 32'b10101010_11111111_01110010_11001100;
        ram[1] = 32'd1;
        for (i = 2; i < 2 ** 6; i = i + 1) begin
            ram[i] = i * 10;
        end
    end

    always @(posedge clk) begin
        if (we & cs) begin
            // case ({BHW,addr[1:0]})
            //     {`SL_BYTE,2'b00}: ram[addr[7:2]][7:0] <= wdata[7:0];
            //     {`SL_BYTE,2'b01}: ram[addr[7:2]][15:8] <= wdata[7:0];
            //     {`SL_BYTE,2'b10}: ram[addr[7:2]][23:16] <= wdata[7:0];
            //     {`SL_BYTE,2'b11}: ram[addr[7:2]][31:24] <= wdata[7:0];
            //     {`SL_HALF,2'b00}: ram[addr[7:2]][15:0] <= wdata[15:0];
            //     {`SL_HALF,2'b01}: ram[addr[7:2]][23:8] <= wdata[15:0];
            //     {`SL_HALF,2'b10}: ram[addr[7:2]][31:16] <= wdata[15:0];
            //     {`SL_HALF,2'b11}: begin
            //         ram[addr[7:2]][31:24] <= wdata[7:0];
            //         ram[addr[7:2]+1][7:0] <= wdata[15:8];
            //     end
            //     {`SL_WORD,2'b00}: ram[addr[7:2]] <= wdata;
            //     {`SL_WORD,2'b01}: begin
            //         ram[addr[7:2]][31:8] <= wdata[23:0];
            //         ram[addr[7:2]+1][7:0] <= wdata[31:24];
            //     end
            //     {`SL_WORD,2'b10}: begin
            //         ram[addr[7:2]][31:16] <= wdata[15:0];
            //         ram[addr[7:2]+1][15:0] <= wdata[31:16];
            //     end
            //     {`SL_WORD,2'b11}: begin
            //         ram[addr[7:2]][31:24] <= wdata[7:0];
            //         ram[addr[7:2]+1][23:0] <= wdata[31:8];
            //     end
            //     default: ram[addr[7:2]] <= ram[addr[7:2]];
            // endcase
            ram[addr[7:2]] <= wdata;
        end 
        // if(we) ram[addr[5:0]] <= wdata;
    end

    // always @(*) begin
        // case (addr[1:0])
        //     2'b00: rdata = {ram[addr[7:2]]};
        //     2'b01: rdata = {ram[addr[7:2]+1][7:0],ram[addr[7:2]][31:8]};
        //     2'b10: rdata = {ram[addr[7:2]+1][15:0],ram[addr[7:2]][31:16]};
        //     2'b11: rdata = {ram[addr[7:2]+1][23:0],ram[addr[7:2]][31:24]};
        // endcase
    // end

    assign rdata = ram[addr[7:2]];
    // assign rdata = ram[addr[5:0]];
endmodule
