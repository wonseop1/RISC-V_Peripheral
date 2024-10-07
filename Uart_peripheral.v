module Uart_peripheral(
    input         clk,
    input         reset,
    input         cs,
    input         wr,  // write =1
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    output        tx,
    input         rx
    );

    wire w_tx_start, w_rx_done;
    wire [7:0] w_rx_data, w_tx_data;

    Uart_BUS U_Uart_BUS(
        .clk(clk),
        .reset(reset),
        .cs(cs),
        .wr(wr),  // write =1
        .addr(addr),
        .wdata(wdata),
        .rx_data(w_rx_data),
        .tx_start(w_tx_start),
        .tx_data(w_tx_data),
        .rdata(rdata),
        .rx_done(w_rx_done)
    );

    uart U_uart(
        // global signal
        .clk(clk),
        .reset(reset),
        // transmitter signal
        .start(w_tx_start),
        .tx_data(w_tx_data),
        .tx_done(),
        .tx(tx),
        // receiver signal
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

endmodule

module Uart_BUS(
    input           clk,
    input           reset,
    input           cs,
    input           wr,  // write =1
    input  [31:0]   addr,
    input  [31:0]   wdata,
    input  [7:0]    rx_data, 
    input           rx_done,
    output          tx_start,
    output [7:0]    tx_data,
    output [31:0]   rdata
);

reg [31:0] regFile [0:2];

reg tx_start_reg;

wire [31:0] tx_reg;       
wire [31:0] rx_reg; 

assign tx_reg   = regFile[0];
assign rx_reg   = regFile[1];
assign tx_start = tx_start_reg;

// write
always @(posedge clk, posedge reset) begin
    if (reset) begin
        regFile[0] <= 0;
        tx_start_reg <= 1'b0;
    end else begin
        if (cs & wr) begin
            regFile[0] <= wdata;
            tx_start_reg <= 1'b1;
        end
        else begin
            tx_start_reg <= 1'b0;
        end
    end
end

// read
always @(posedge clk, posedge reset) begin
    if (reset) begin
        regFile[1] <= 0;
    end else begin
        regFile[1] <= {24'b0, rx_data};
    end
end

assign tx_data = tx_reg[7:0];
assign rdata   = regFile[addr[3:2]];

always @(posedge clk , posedge reset) begin
    if(reset) begin
        regFile[2] <=0;
    end
    else begin
        if(rx_done) begin
            regFile[2][0] <= 1'b1;
        end
        if(cs & ~wr)begin
            if(addr[3:2] == 2'd1) begin
                regFile[2][0] <= 1'b0;
            end
        end
    end
end

endmodule