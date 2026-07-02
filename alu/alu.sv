//risc-v 32 bit arch cpu alu implementation
import alu_ops::*;
module rv32i_alu (
    input  logic [31:0] operand_1,
    input  logic [31:0] operand_2,
    input  alu_operation_t operation,
    output logic [31:0] result,
    output logic zero
);

    always_comb begin
        case (operation)
            default: result = 32'd0;
            ALU_ADD: result = operand_1 + operand_2;
            ALU_SUB: result = operand_1 - operand_2;
            ALU_AND: result = operand_1 & operand_2;
            ALU_OR:  result = operand_1 | operand_2;
            ALU_XOR: result = operand_1 ^ operand_2;
            ALU_SLL: result = operand_1 << operand_2[4:0];
            ALU_SRL: result = operand_1 >> operand_2[4:0];
            ALU_SRA: result = $signed(operand_1) >>> operand_2[4:0];
            ALU_SLT: result = $signed(operand_1) < $signed(operand_2) ? 32'd1 : 32'd0;
            ALU_SLTU: result = operand_1 < operand_2 ? 32'd1 : 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule