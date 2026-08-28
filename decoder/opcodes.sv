package opcodes;
    typedef enum logic [6:0] {
        OP_RTYPE = 7'b0110011,
        OP_ITYPE = 7'b0010011,
        OP_LOAD = 7'b0000011,
        OP_STORE = 7'b0100011,
        OP_LUI = 7'b0110111,
        OP_AUIPC = 7'b0010111,
        OP_JTYPE = 7'b1101111,
        OP_JALR = 7'b1100111
    } opcode_t;
endpackage