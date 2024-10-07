`timescale 1ns / 1ps

module GPO (
    input         clk,
    input         reset,
    input         cs,
    input         wr,
    input         addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    output [ 15:0] gpo
);

    reg [15:0] regGpo; //odr

    assign gpo = regGpo;

    always @(posedge clk , posedge reset) begin
        if(reset) begin
            regGpo <= 0;
        end 
        else begin
            if(cs & wr) regGpo <= wdata[15:0];
        end
    end

    assign rdata = {16'b0,regGpo};

endmodule
