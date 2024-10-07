`timescale 1ns / 1ps

module PWM(
    input clk,
    input reset,
    input wr,
    input cs,
    input [31:0] addr,
    input [31:0] wdata,

    output [31:0] rdata,
    output  led
    );

    wire [10:0] w_pwmNum, w_comparatorNum;

    PWMIP U_PWMIP(
        .clk(clk),
        .reset(reset),
        .pwmNum(w_pwmNum),
        .comparatorNum(w_comparatorNum),
    
        .led(led)
);

    PWM_BUS U_PWM_BUS(
        .clk(clk),
        .reset(reset),
        .we(wr),
        .cs(cs),
        .addr(addr),
        .wdata(wdata),
    

        .rdata(rdata),

		    //ip 
        .pwmNum(w_pwmNum),
        .comparatorNum(w_comparatorNum)
);

endmodule


module PWMIP (
    input clk,
    input reset,
    input [10:0] pwmNum,
    input [10:0] comparatorNum,
    
    output led
);

    wire [10:0] w_aDuty;
	
    counter_pwm U_counter (
	    .clk(clk),
	    .reset(reset),
	    .a(pwmNum),

	    .aDuty(w_aDuty)
);
    
    comparator U_comparator (
	    .a(w_aDuty),
	    .b(comparatorNum),
    
	    .y(led)
);

    
endmodule





module counter_pwm (
    input  clk,
    input  reset,
    input [10:0] a,

    output [10:0] aDuty
);

    reg [10:0] r_counter;
    assign aDuty = r_counter;
  

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end 
        else begin
            if (r_counter == a - 1) r_counter <= 0;
            else r_counter <= r_counter + 1;
		end
    end
endmodule

module comparator (
    input  [10:0] a,
    input  [10:0] b,
    
    output  y
);
    assign y = a<b;
    
endmodule
//////////////////////////////

module PWM_BUS (
    input clk,
    input reset,
    input we,
    input cs,
    input [31:0] addr,
    input [31:0] wdata,
    

    output [31:0] rdata,

    //ip 
    output [10:0] pwmNum,
    output [10:0] comparatorNum

);

    reg [31:0] pwmFile [0:1];


    assign  pwmNum = pwmFile[0][10:0];  ///100
    assign  comparatorNum = pwmFile[1][10:0];//50
  
    //read
    assign rdata = pwmFile [addr[2]];

    //write
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            pwmFile[0] <= 0;
            pwmFile[1] <= 0;
       
        end

        else begin
            if (we & cs) begin
                pwmFile[addr[2]] <= wdata;
            end
        end
    end

    
endmodule