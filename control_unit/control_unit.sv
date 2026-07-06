//fetch decode exec cycle.
import alu_ops::*;
import opcodes::*;
module riscv32i_control_unit(
    input logic CLK100MHZ,
    input logic reset, 
    input opcode_t opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic pc_write, //advance pc
    output logic ir_write, //latch fetched instruction
    output logic alu_src,
    output alu_operation_t alu_op,
    output logic reg_write
);


    typedef enum logic [1:0] {FETCH, DECODE, EXECUTE, WRITEBACK} state_t;
    state_t state = FETCH;
    
    always_ff @(posedge CLK100MHZ) begin
        if(reset) state <= FETCH;
        else case(state)
            FETCH : state <= DECODE;
            DECODE : state <= EXECUTE;
            EXECUTE : state <= WRITEBACK;
            WRITEBACK : state <= FETCH; 
            default : state <= FETCH;
        endcase
    end



    always_comb begin
        pc_write = 1'b0;
        ir_write = 1'b0;
        alu_src = 1'b0;
        alu_op = ALU_ADD;
        reg_write = 1'b0;
        case(state)
            FETCH : begin
                pc_write = 1'b1;
                ir_write = 1'b1;
            end
            DECODE : begin
                //waiting for datapath.
            end
            EXECUTE : begin 
                case(opcode)
                    OP_RTYPE : begin
                        alu_src = 1'b0; //operand 2 is a register value (rs2)
                        case(funct3)
                            default : alu_op = ALU_ADD;
                            3'b000 : alu_op = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
                            3'b111 : alu_op = ALU_AND;
                            3'b110 : alu_op = ALU_OR;
                            3'b100 : alu_op = ALU_XOR;
                            3'b001 : alu_op = ALU_SLL;
                            3'b101 : alu_op = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
                            3'b010 : alu_op = ALU_SLT;
                            3'b011 : alu_op = ALU_SLTU;
                        endcase
                    end
                    OP_ITYPE : begin
                        alu_src = 1'b1; //immediate is operand 2
                        case(funct3)
                            default : alu_op = ALU_ADD;
                            3'b000 : alu_op = ALU_ADD;
                            3'b111 : alu_op = ALU_AND;
                            3'b110 : alu_op = ALU_OR;
                            3'b100 : alu_op = ALU_XOR;
                            3'b010 : alu_op = ALU_SLT;
                            3'b011 : alu_op = ALU_SLTU;                        
                        endcase
                    end
                endcase
            end
            WRITEBACK : begin 
                reg_write = 1'b1;
            end
        endcase
    end
endmodule
