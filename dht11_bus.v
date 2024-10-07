module top_dht11_bus (
    input         clk,
    input         rst,
    input         cs,
    input         wr,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    inout         dht_signal
);

    wire [7:0] w_hum_high, w_hum_low, w_tem_high, w_tem_low, w_checksum;
    wire [7:0] w_hum_high_ah, w_hum_high_al, w_hum_low_ah,w_hum_low_al,w_tem_high_ah,w_tem_high_al,w_tem_low_ah,w_tem_low_al,w_checksum_ah,w_checksum_al;
    wire state_done;
    top_dht11 u_dht11 (
        .clk          (clk),
        .rst          (rst),
        .dht_signal   (dht_signal),
        .hum_high     (w_hum_high),
        .hum_low      (w_hum_low),
        .tem_high     (w_tem_high),
        .tem_low      (w_tem_low),
        .checksum     (w_checksum),
        .state_done(state_done)
    );

    decimal_to_ascii U_decimal_to_ascii_HUMH(
    .decimal_in(w_hum_high),   // 8-bit decimal input
    .ascii_tens(w_hum_high_ah), // ASCII code for tens place
    .ascii_ones(w_hum_high_al)  // ASCII code for ones place
    );

    decimal_to_ascii U_decimal_to_ascii_HUML(
    .decimal_in(w_hum_low),   // 8-bit decimal input
    .ascii_tens(w_hum_low_ah), // ASCII code for tens place
    .ascii_ones(w_hum_low_al)  // ASCII code for ones place
    );

    decimal_to_ascii U_decimal_to_ascii_TEMH(
    .decimal_in(w_tem_high),   // 8-bit decimal input
    .ascii_tens(w_tem_high_ah), // ASCII code for tens place
    .ascii_ones(w_tem_high_al)  // ASCII code for ones place
    );

    decimal_to_ascii U_decimal_to_ascii_TEML(
    .decimal_in(w_tem_low),   // 8-bit decimal input
    .ascii_tens(w_tem_low_ah), // ASCII code for tens place
    .ascii_ones(w_tem_low_al)  // ASCII code for ones place
    );

    decimal_to_ascii U_decimal_to_ascii_CEHCK(
    .decimal_in(w_checksum),   // 8-bit decimal input
    .ascii_tens(w_checksum_ah), // ASCII code for tens place
    .ascii_ones(w_checksum_al)  // ASCII code for ones place
    );

    dht11_bus u_dht11_bus (
        .clk  (clk),
        .rst  (rst),
        .cs   (cs),
        .wr   (wr),
        .addr (addr),
        .wdata(wdata),
        .rdata(rdata),
        .hum_high  (w_hum_high_ah),
        .hum_high1  (w_hum_high_al),
        .hum_low   (w_hum_low_ah),
        .hum_low1   (w_hum_low_al),
        .tem_high  (w_tem_high_ah),
        .tem_high1  (w_tem_high_al),
        .tem_low   (w_tem_low_ah),
        .tem_low1   (w_tem_low_al),
        .checksum  (w_checksum_ah),
        .checksum1  (w_checksum_al),
        .state_done (state_done)
    );


endmodule

module dht11_bus (
    input         clk,
    input         rst,
    input         cs,
    input         wr,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    input  [ 7:0] hum_high,
    input  [ 7:0] hum_high1,
    input  [ 7:0] hum_low,
    input  [ 7:0] hum_low1,
    input  [ 7:0] tem_high,
    input  [ 7:0] tem_high1,
    input  [ 7:0] tem_low,
    input  [ 7:0] tem_low1,
    input  [ 7:0] checksum,
    input  [ 7:0] checksum1,
    input         state_done
);

    reg [31:0] regDHT[0:10];
    reg [31:0] temp  [0:9];



    always @(*) begin
        if (clk) begin
            temp[0] = hum_high;
            temp[1] = hum_high1;
            temp[2] = hum_low;
            temp[3] = hum_low1;
            temp[4] = tem_high;
            temp[5] = tem_high1;
            temp[6] = tem_low;
            temp[7] = tem_low1;
            temp[8] = checksum;
            temp[9] = checksum1;
        end else begin
            temp[0] = temp[0];
            temp[1] = temp[1];
            temp[2] = temp[2];
            temp[3] = temp[3];
            temp[4] = temp[4];
            temp[5] = temp[5];
            temp[6] = temp[6];
            temp[7] = temp[7];
            temp[8] = temp[8];
            temp[9] = temp[9];
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            regDHT[0] <= 0;
            regDHT[1] <= 0;
            regDHT[2] <= 0;
            regDHT[3] <= 0;
            regDHT[4] <= 0;
            regDHT[5] <= 0;
            regDHT[6] <= 0;
            regDHT[7] <= 0;
            regDHT[8] <= 0;
            regDHT[9] <= 0;
        end else begin
            regDHT[0] <= {24'b0, temp[0]};
            regDHT[1] <= {24'b0, temp[1]};
            regDHT[2] <= {24'b0, temp[2]};
            regDHT[3] <= {24'b0, temp[3]};
            regDHT[4] <= {24'b0, temp[4]};
            regDHT[5] <= {24'b0, temp[5]};
            regDHT[6] <= {24'b0, temp[6]};
            regDHT[7] <= {24'b0, temp[7]};
            regDHT[8] <= {24'b0, temp[8]};
            regDHT[9] <= {24'b0, temp[9]};
        end
    end


    assign rdata = regDHT[addr[5:2]];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            regDHT[10] <= 0;
        end else begin
            if (state_done) begin
                regDHT[10][0] <= 1'b1;
            end
            if (cs & ~wr) begin
                if (addr[5:2]==4'd9) regDHT[10][0] <= 1'b0;
            end

        end
    end

endmodule

module decimal_to_ascii (
    input [7:0] decimal_in,   // 8-bit decimal input
    output reg [7:0] ascii_tens, // ASCII code for tens place
    output reg [7:0] ascii_ones  // ASCII code for ones place
);

    always @(*) begin
        // Calculate the ASCII code for tens place
        ascii_tens = (decimal_in / 10) + 8'd48;  // Convert tens digit to ASCII
        // Calculate the ASCII code for ones place
        ascii_ones = (decimal_in % 10) + 8'd48;   // Convert ones digit to ASCII
    end

endmodule
