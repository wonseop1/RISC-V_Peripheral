`define OP_TYPE_R 7'b0110011
`define OP_TYPE_IL 7'b0000011
`define OP_TYPE_I 7'b0010011
`define OP_TYPE_S 7'b0100011
`define OP_TYPE_B 7'b1100011
`define OP_TYPE_J 7'b1101111
`define OP_TYPE_JI 7'b1100111
`define OP_TYPE_U 7'b0110111
`define OP_TYPE_UA 7'b0010111

`define ADD 4'b0000
`define SUB 4'b1000
`define SLL 4'b0001
`define SRL 4'b0101
`define SRA 4'b1101
`define SLT 4'b0_010
`define SLTU 4'b0_011
`define XOR 4'b0_100
`define OR 4'b0_110
`define AND 4'b0_111

`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111

`define SL_BYTE 2'b00
`define SL_HALF 2'b01
`define SL_WORD 2'b10

`define UNSIGNED 1'b0
`define SIGNED 1'b1