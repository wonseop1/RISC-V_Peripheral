`timescale 1ns / 1ps

`include "defines.v"

module RV32I_Core (
    input         clk,
    input         reset,
    input  [31:0] instrData,
    input  [31:0] DRdData,
    output [31:0] instrAddr,
    output        DWe,
    output [31:0] DAddr,
    output [31:0] DWrData,
    output [1:0] BHW
);
    wire regFileWe, aluSrcMuxSel, rfWdSrcMuxSel;
    wire [3:0] aluControl;
    wire [2:0] extType;
    wire branch, jal, jalr, u, ua;
    
    wire sign;

    DataPath_pref U_DP (
        .clk          (clk),
        .reset        (reset),
        .instrData    (instrData),
        .regFileWe    (regFileWe),
        .aluControl   (aluControl),
        .aluSrcMuxSel (aluSrcMuxSel),
        .rfWdSrcMuxSel(rfWdSrcMuxSel),
        .instrAddr    (instrAddr),
        .DRdData      (DRdData),
        .DWrData      (DWrData),
        .DAddr        (DAddr),
        .extType      (extType),
        .branch       (branch),
        .jal          (jal),
        .jalr         (jalr),
        .u            (u),
        .ua           (ua),
        .BHW          (BHW),
        .sign         (sign)
    );

    ControlUnit_pref U_CU (
        .instrData    (instrData),
        .regFileWe    (regFileWe),
        .aluControl   (aluControl),
        .aluSrcMuxSel (aluSrcMuxSel),
        .rfWdSrcMuxSel(rfWdSrcMuxSel),
        .extType      (extType),
        .DWe          (DWe),
        .branch       (branch),
        .jal          (jal),
        .jalr         (jalr),
        .u            (u),
        .ua           (ua),
        .BHW          (BHW),
        .sign         (sign)
    );

endmodule

module DataPath_pref (
    input         clk,
    input         reset,
    input  [31:0] instrData,
    input         regFileWe,
    input         aluSrcMuxSel,
    input         rfWdSrcMuxSel,
    input  [ 2:0] extType,
    input  [31:0] DRdData,
    input  [ 3:0] aluControl,
    input         branch,
    input         jal,
    input         jalr,
    input         u,
    input         ua,
    input  [ 1:0] BHW,
    input         sign,
    output [31:0] DWrData,
    output [31:0] instrAddr,
    output [31:0] DAddr
);
    wire [31:0] w_RegFileRD1, w_RegFileRD2;
    wire [31:0] w_aluResult, w_PCAdderResult;
    wire [31:0] w_ImmExtOut, w_AluSrcMuxOut, w_RfWdSrcMuxOut;
    wire [31:0] w_PCSrcMuxOut,w_BranchPCAdderResult;
    wire [31:0] w_JalRfWdSrcMuxOut;
    wire [31:0] w_JalRPCSrcMuxOut;
    wire [31:0] w_UaRfWdSrcMuxOut;
    wire w_btaken, PCSrcMuxSel;

    wire [4:0] w_RAddr1;
    assign w_RAddr1 = ({5{~u}}) & instrData[19:15];
    assign PCSrcMuxSel = jal | (branch & w_btaken);
    assign DAddr   = w_aluResult;
    assign DWrData = w_RegFileRD2;

    RegisterFile_pref U_RegFile (
        .clk   (clk),
        .we    (regFileWe),
        .RAddr1(w_RAddr1),
        .RAddr2(instrData[24:20]),
        .WAddr (instrData[11:7]),
        .WData (w_UaRfWdSrcMuxOut),
        .RData1(w_RegFileRD1),
        .RData2(w_RegFileRD2),
        .BHW   (BHW),
        .sign  (sign)
    );

    mux_2x1 U_UaRfWdSrcMux (
        .sel(ua),
        .a  (w_JalRfWdSrcMuxOut),
        .b  (w_BranchPCAdderResult),
        .y  (w_UaRfWdSrcMuxOut)
    );

    mux_2x1 U_JalRfWdSrcMux (
        .sel(jal),
        .a  (w_RfWdSrcMuxOut),
        .b  (w_PCAdderResult),
        .y  (w_JalRfWdSrcMuxOut)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .a  (w_RegFileRD2),
        .b  (w_ImmExtOut),
        .y  (w_AluSrcMuxOut)
    );

    alu U_ALU (
        .a         (w_RegFileRD1),
        .b         (w_AluSrcMuxOut),
        .aluControl(aluControl),
        .result    (w_aluResult),
        .btaken    (w_btaken)
    );

    mux_2x1 U_RfWdSrcMux (
        .sel(rfWdSrcMuxSel),
        .a  (w_aluResult),
        .b  (DRdData),
        .y  (w_RfWdSrcMuxOut)
    );

    extend U_Extend (
        .instrData(instrData[31:7]),
        .immext   (w_ImmExtOut),
        .extType  (extType)
    );

    register U_PC (
        .clk  (clk),
        .reset(reset),
        .d    (w_JalRPCSrcMuxOut),
        .q    (instrAddr)
    );

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .a  (w_PCAdderResult),
        .b  (w_BranchPCAdderResult),
        .y  (w_PCSrcMuxOut)
    );


    mux_2x1 U_JalRPCSrcMux (
        .sel(jalr),
        .a  (w_PCSrcMuxOut),
        .b  (w_aluResult),
        .y  (w_JalRPCSrcMuxOut)
    );

    adder U_BranchPCAdder (
        .a(w_ImmExtOut),
        .b(instrAddr),
        .y(w_BranchPCAdderResult)
    );

    adder U_PCAdder (
        .a(instrAddr),
        .b(32'd4),
        .y(w_PCAdderResult)
    );

endmodule


module mux_2x1 (
    input             sel,
    input      [31:0] a,
    input      [31:0] b,
    output reg [31:0] y
);
    always @(*) begin
        case (sel)
            1'b0: y = a;
            1'b1: y = b;
        endcase
    end
endmodule

module extend (
    input      [31:7] instrData,
    input      [ 2:0] extType,    //*****add 0823
    output reg [31:0] immext
);
    localparam RType = 3'd0, ILType = 3'd1, IType = 3'd2, SType = 3'd3, BType = 3'd4, UType = 3'd5, JType = 3'd6, ISType = 3'd7;
    always @(*) begin
        case (extType)
            RType: immext = 32'bx;
            ILType: immext = {{20{instrData[31]}}, instrData[31:20]};
            IType: immext = {{20{instrData[31]}}, instrData[31:20]};
            ISType: immext = {{27{instrData[31]}}, instrData[24:20]};
            SType:
            immext = {{20{instrData[31]}}, instrData[31:25], instrData[11:7]};
            BType:
            immext = {{20{instrData[31]}}, instrData[7], instrData[30:25], instrData[11:8], 1'b0};
            UType: immext = {instrData[31:12], 12'b0};
            JType:
            immext = {
                {12{instrData[31]}},
                instrData[19:12],
                instrData[20],
                instrData[30:21],
                1'b0
            };
            default: immext = 32'bx;
        endcase
    end


endmodule

module RegisterFile_pref (
    input         clk,
    input         we,
    input  [ 4:0] RAddr1,
    input  [ 4:0] RAddr2,
    input  [ 4:0] WAddr,
    input  [31:0] WData,
    input  [ 1:0] BHW,
    input         sign,
    output [31:0] RData1,
    output [31:0] RData2
);
    reg [31:0] RegFile[0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            
            if(i==4) RegFile[i] = 32'b11111010_01011010_11011000_00101011;
            // else RegFile[i] = 4 * i+100;
            else if(i==0) RegFile[i] = 0;
            else RegFile[i] = 3 * i;
            // RegFile[i] = 3 * i;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            case (BHW)
                `SL_BYTE: RegFile[WAddr] <= (sign == `SIGNED) ? {{24{WData[7]}},WData[7:0]} : {24'd0,WData[7:0]};
                `SL_HALF: RegFile[WAddr] <= (sign == `SIGNED) ? {{16{WData[15]}},WData[15:0]} : {16'd0,WData[15:0]};
                `SL_WORD: RegFile[WAddr] <= WData;
                default:  RegFile[WAddr] <= WData;
            endcase
            
            
            
        end 
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 0;
endmodule

module register (
    input             clk,
    input             reset,
    input      [31:0] d,
    output reg [31:0] q
);

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end

endmodule

module alu (
    input         [31:0] a,
    input         [31:0] b,
    input         [ 3:0] aluControl,
    output reg    [31:0] result,
    output reg           btaken
);
    always @(*) begin
        case (aluControl)
            `ADD:    result = a + b;  // 0_000 ADD
            `SUB:    result = a - b;  // 1_000 SUB
            `SLL:    result = a << b;  // 0_001 SLL
            `SRL:    result = a >> b;  // 0_101 SRL
            // `SRA: result = (a>>b)|({32{a[31]}}<<(32-b)); // `SRA: result = $signed a >>> b;  // 1_101 SRA
            `SRA:    result = $signed(a) >>> b[4:0];
            `SLT:    result = $signed(a) < $signed(b);  // 0_010 SLT
            `SLTU:   result = a < b;  // 0_011 SLTU
            `XOR:    result = a ^ b;  // 0_100 XOR
            `OR:     result = a | b;  // 0_110 OR
            `AND:    result = a & b;  // 0_111 AND
            default: result = 32'bx;
        endcase
    end
    always @(*) begin
        case (aluControl[2:0])
            `BEQ:    btaken = (a == b);
            `BNE:    btaken = (a != b);
            `BLT:    btaken = $signed(a) < $signed(b);
            `BGE:    btaken = $signed(a) >= $signed(b);
            `BLTU:   btaken = a < b;
            `BGEU:   btaken = a >= b;
            default: btaken = 1'bx;
        endcase
    end
endmodule

module adder (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] y
);
    assign y = a + b;
endmodule

module ControlUnit_pref (
    input      [31:0] instrData,
    output            regFileWe,
    output reg [ 3:0] aluControl,
    output            aluSrcMuxSel,
    output            rfWdSrcMuxSel,
    output     [ 2:0] extType,
    output            DWe,
    output            branch,
    output            jal,
    output            jalr,
    output            u,
    output            ua,
    output     [ 1:0] BHW,
    output            sign
);
    //localparam RType = 3'd0, ILType = 3'd1, IType = 3'd2, SType = 3'd3, BType = 3'd4, UType = 3'd5, JType = 3'd6, ISType = 3'd7;

    wire [6:0] opcode = instrData[6:0];
    wire [2:0] func3 = instrData[14:12];
    wire [6:0] func7 = instrData[31:25];
    reg [11:0] controls;
    reg [2:0] SLcontrols;
    assign {regFileWe, aluSrcMuxSel, rfWdSrcMuxSel, DWe, extType, branch, jal, jalr,u,ua} = controls;
    assign {sign,BHW} = SLcontrols;
    always @(*) begin
        case (opcode)
            // regFileWe_aluSrcMuxSel_rfWdSrcMuxSel_DWe_extType_branch_jal_jalr_u_ua
            `OP_TYPE_R:  controls = 12'b1_0_0_0_xxx_0_0_0_0_0;  // R-type
            `OP_TYPE_IL: controls = 12'b1_1_1_0_001_0_0_0_0_0;  // IL-type  
            `OP_TYPE_I:  controls = 12'b1_1_0_0_001_0_0_0_0_0;  // I-type
            `OP_TYPE_S:  controls = 12'b0_1_x_1_011_0_0_0_0_0;  // S-type
            `OP_TYPE_B:  controls = 12'b0_0_x_0_100_1_0_0_0_0;  //B-type
            `OP_TYPE_J:  controls = 12'b1_x_x_0_110_0_1_0_0_0;  //J-type
            `OP_TYPE_JI: controls = 12'b1_1_x_0_001_0_x_1_0_0;//JI-type
            `OP_TYPE_U:  controls = 12'b1_1_0_0_101_0_0_0_1_0;//U-type
            `OP_TYPE_UA:  controls= 12'b1_x_x_0_101_0_0_0_0_1;//UA-type
            default:     controls = 12'bx;
        endcase
    end

    always @(*) begin
        case (opcode)
            `OP_TYPE_R: aluControl = {func7[5], func3};
            `OP_TYPE_IL: aluControl = `ADD;  //ADD
            `OP_TYPE_I: begin
                case (func3)
                    3'b101:  aluControl = {func7[5], func3};
                    default: aluControl = {1'b0, func3};
                endcase
                // if((func3 == 3'b001) | (func3 == 3'b101)) aluControl = {func7[5], func3};
                // else aluControl = {1'b0, func3};
            end
            `OP_TYPE_S: aluControl = `ADD;
            `OP_TYPE_B: aluControl = {1'b0, func3};

            `OP_TYPE_JI: aluControl = `ADD;
            `OP_TYPE_U: aluControl = `ADD;
            default: aluControl = 4'bxxx;
        endcase
    end
    //SLcontrols = {sign, BHW} // unsign:0 sign:1  // Byte : 00, Half : 01, Word : 10
    always @(*) begin
        case (opcode)
            `OP_TYPE_IL: SLcontrols = func3;
            `OP_TYPE_S: SLcontrols = func3;
            default: SLcontrols = 3'b0_10;
        endcase
    end
    // always @(*) begin
    //     case (opcode)
    //         `OP_TYPE_R: extType = RType;
    //         `OP_TYPE_IL: extType = ILType;
    //         `OP_TYPE_I: begin
    //             if((func3 == 3'b001) | (func3 == 3'b101)) extType = ISType;
    //             else extType = IType;
    //         end
    //         `OP_TYPE_S: extType = SType;
    //         `OP_TYPE_B: extType = BType;
    //         `OP_TYPE_U: extType = UType;
    //         `OP_TYPE_UA: extType = UType;
    //         `OP_TYPE_J: extType = JType;
    //         `OP_TYPE_JI: extType = IType;

    //         default: extType = 3'bx;
    //     endcase
    // end

endmodule
