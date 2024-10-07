`timescale 1ns / 1ps

module RISCV_MCU (
    input        clk,
    input        reset,
    output [15:0] GPOA,
    input  [7:0] GPIB,
    inout  [7:0] GPIOC,
    output [3:0] fndCom,
    output [7:0] fndFont,
    output       tx,
    input        rx,
    inout        dht_signal,
    input        echo,
    output       trig,
    output       o_pwm
);
    wire [31:0] instrData, instrAddr;
    wire [31:0] DRdData, DWrData, DAddr;
    wire       DWe;
    wire [1:0] BHW;
    wire [9:0] w_addrSel;
    wire [31:0] w_ramRdData, w_gpoRdData, w_gpiRdData, w_gpioRdData,w_fndRdData, w_uartRdData, w_dht11RDdata, w_ultrasonicRDdata;
    wire [31:0] w_pwmRDdata, w_RTCRDdata;
    RV32I_Core U_MCU (
        .clk      (clk),
        .reset    (reset),
        .instrData(instrData),
        .instrAddr(instrAddr),
        .DAddr    (DAddr),
        .DRdData  (DRdData),
        .DWrData  (DWrData),
        .DWe      (DWe),
        .BHW      (BHW)
    );

    ROM U_ROM (
        .addr(instrAddr),
        .data(instrData)
    );

    addrDecoder U_AddrDec (
        .DAddr(DAddr),
        .sel  (w_addrSel)
    );

    addrMux U_AddrMux (
        .DAddr(DAddr),
        .a    (w_ramRdData),
        .b    (w_gpoRdData),
        .c    (w_gpiRdData),
        .d    (w_gpioRdData),
        .e    (w_fndRdData),
        .f    (w_uartRdData),
        .g    (w_dht11RDdata),
        .h    (w_ultrasonicRDdata),
        .i    (w_pwmRDdata),
        .j    (w_RTCRDdata),
        .y    (DRdData)
    );

    RAM U_RAM (
        .clk  (clk),
        .cs   (w_addrSel[0]),
        .we   (DWe),
        .addr (DAddr[7:0]),
        .wdata(DWrData),
        .rdata(w_ramRdData),
        .BHW  (BHW)
    );

    GPO U_GPO (
        .clk  (clk),
        .reset(reset),
        .cs   (w_addrSel[1]),
        .wr   (DWe),
        .addr (DAddr),
        .wdata(DWrData),
        .rdata(w_gpoRdData),
        .gpo  (GPOA)
    );

    GPI U_GPIB (
        .clk  (clk),
        .reset(reset),
        .cs   (w_addrSel[2]),
        .wr   (DWe),
        .addr (DAddr),
        .wdata(DWrData),
        .rdata(w_gpiRdData),
        .gpi  (GPIB)
    );

    GPIO U_GPIO (
        .clk   (clk),
        .reset (reset),
        .cs    (w_addrSel[3]),
        .wr    (DWe),
        .addr  (DAddr),
        .wdata (DWrData),
        .rdata (w_gpioRdData),
        .ioport(GPIOC)
    );

    FND_ph U_FND_ph (
        .clk(clk),
        .reset(reset),
        .cs(w_addrSel[4]),
        .wr(DWe),  //write =1
        .addr(DAddr),
        .wdata(DWrData),
        .rdata(w_fndRdData),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );

    Uart_peripheral U_Uart_peripheral (
        .clk(clk),
        .reset(reset),
        .cs(w_addrSel[5]),
        .wr(DWe),  //write =1
        .addr(DAddr),
        .wdata(DWrData),
        .rdata(w_uartRdData),
        .tx(tx),
        .rx(rx)
    );

    top_dht11_bus U_DHT11BUS (
        .clk(clk),
        .rst(reset),
        .cs(w_addrSel[6]),
        .wr(DWe),
        .addr(DAddr),
        .wdata(DWrData),
        .rdata(w_dht11RDdata),
        .dht_signal(dht_signal)
    );

    Ultrasonic U_ultrasonice_per (
        .clk(clk),
        .reset(reset),
        .wr(DWe),
        .cs(w_addrSel[7]),
        .addr(DAddr),
        .wdata(DWrData),
        .rdata(w_ultrasonicRDdata),
        .echo(echo),
        .trig(trig)
    );

    PWM U_pwmPer (
        .clk(clk),
        .reset(reset),
        .wr(DWe),
        .cs(w_addrSel[8]),
        .addr(DAddr),
        .wdata(DWrData),
        .rdata(w_pwmRDdata),
        .led(o_pwm)
    );

    RTC U_RTCPer (
        .clk(clk),
        .reset(reset),
        .wr(DWe),
        .cs(w_addrSel[9]),
        .addr(DAddr),
        .wdata(DWrData),
        .rdata(w_RTCRDdata)
    );

endmodule


module addrDecoder (
    input      [31:0] DAddr,
    output reg [ 9:0] sel
);
    always @(*) begin
        casex (DAddr)
            32'h0000_02xx: sel = 10'b0000000001;  //RAM
            32'h4000_00xx: sel = 10'b0000000010;  //GPO
            32'h4000_01xx: sel = 10'b0000000100;  //GPI
            32'h4000_02xx: sel = 10'b0000001000;  //GPIO
            32'h4000_03xx: sel = 10'b0000010000;  //FND
            32'h4000_08xx: sel = 10'b0000100000;  //uart
            32'h4000_04xx: sel = 10'b0001000000;  //dht
            32'h4000_05xx: sel = 10'b0010000000;  //ultrasonic
            32'h4000_06xx: sel = 10'b0100000000;  //pwm
            32'h4000_07xx: sel = 10'b1000000000;
            default: sel = 10'bxx;
        endcase
    end

endmodule

module addrMux (
    input      [31:0] DAddr,
    input      [31:0] a,
    input      [31:0] b,
    input      [31:0] c,
    input      [31:0] d,
    input      [31:0] e,
    input      [31:0] f,
    input      [31:0] g,
    input      [31:0] h,
    input      [31:0] i,
    input      [31:0] j,
    output reg [31:0] y
);
    always @(*) begin
        casex (DAddr)
            32'h0000_02xx: y = a;  //RAM
            32'h4000_00xx: y = b;  //GPO
            32'h4000_01xx: y = c;  //GPI
            32'h4000_02xx: y = d;  //GPIO
            32'h4000_03xx: y = e;  //FND
            32'h4000_08xx: y = f;  //uart
            32'h4000_04xx: y = g;  //DHT
            32'h4000_05xx: y = h;  //ultrasonic
            32'h4000_06xx: y = i;  //pwm
            32'h4000_07xx: y = j;  //RTC
            default: y = 32'bx;
        endcase
    end

endmodule
