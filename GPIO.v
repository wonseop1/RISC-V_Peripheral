`timescale 1ns / 1ps

module GPIO(
    input         clk,
    input         reset,
    input         cs,
    input         wr,//write =1
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    inout  [ 7:0] ioport
    );

    reg [31:0] regGpio [0:2];
    wire [31:0] MODER = regGpio[0];
    wire [31:0] IDR = regGpio[1];
    wire [31:0] ODR = regGpio[2];

    //read
    assign rdata = regGpio[addr[3:2]];
    
    //write

    always @(posedge clk , posedge reset) begin
        if(reset) begin
            regGpio[0] <= 0; //ModeR
            regGpio[2] <= 0; //ODR
        end
        else begin
            if(cs & wr) begin
                // regGpio[0] <= 0;
                // regGpio[2] <= 0;
                case (addr[3:2])
                    2'b00: regGpio[0] <= wdata; //ModeR 
                    2'b10: regGpio[2] <= wdata; //ODR 
                endcase    
            end
        end
    end

    // assign IDR[0] = MODER[0] ? 1'bz : ioport[0];
    // wire [7:0] ioport_temp;

    

    integer i;
    always @(posedge clk, posedge reset) begin
        if(reset) regGpio[1]<=0;
        else begin
            for(i=0;i<8;i=i+1) begin
                // if(~MODER[i]) regGpio [1][i] <= ioport_temp[i]; //IDR
                if(~MODER[i]) regGpio [1][i] <= ioport[i];
            end
        end
    end




    genvar j;
    generate
        for (j = 0; j<8; j=j+1) begin
            // bufif1 bf1 (ioport_temp[j],ioport[j],~MODER[j]);
            // assign ioport[j] = MODER[j] ? ODR[j] : ioport_temp[j];
            assign ioport[j] = MODER[j] ? ODR[j] : 1'bz;     
        end
    endgenerate

endmodule
