module riscv32i_decoder(
    input [31:0] instr,
    output logic [6:0] opcode,
    output logic [4:0] rd,
    output logic [4:0] rs1, rs2,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [31:0] immediate
);

    assign funct7 = instr[31:25];
    assign rs2 = instr[24:20];
    assign rs1 = instr [19:15];
    assign funct3 = instr[14:12];
    assign rd = instr[11:7];
    assign opcode = instr[6:0];

    always_comb begin
        case(opcode)
            default                           : immediate = 32'd0; //def
            7'b0010011, 7'b0000011, 7'b1100111 : immediate = {{20{instr[31]}}, instr[31:20]}; //i type
            7'b0100011                        : immediate = {{20{instr[31]}}, instr[31:25], instr[11:7]}; //s type
            7'b1100011                        : immediate = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; //b type
            7'b0110111, 7'b0010111            : immediate = {instr[31:12], 12'd0}; //u type
            7'b1101111                        : immediate = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; //j type
        endcase
    end
endmodule