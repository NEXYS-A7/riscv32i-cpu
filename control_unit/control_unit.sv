//fetch decode exec cycle.
import alu_ops::*;
import opcodes::*;
module riscv32i_control_unit(
    input logic CLK100MHZ,
    input logic reset, 
    input opcode_t opcode,
    input logic [31:0] immediate,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic pc_write, //advance pc
    output logic ir_write, //latch fetched instruction
    output logic [1:0] alu_src_a,
    output logic alu_src,
    output alu_operation_t alu_op,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] wb_src,
    output logic pc_src
);


    typedef enum logic [2:0] {FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK} state_t;
    state_t state = FETCH;
    
    always_ff @(posedge CLK100MHZ) begin
        if(reset) state <= FETCH;
        else case(state)
            FETCH : state <= DECODE;
            DECODE : state <= EXECUTE;
            EXECUTE : begin
                case(opcode)
                    OP_LOAD : state <= MEMORY;
                    OP_STORE : state <= MEMORY;
                    default : state <= WRITEBACK;
                endcase
            end
            MEMORY : begin
                case(opcode)
                    OP_LOAD : state <= WRITEBACK;
                    default : state <= FETCH;
                endcase
            end
            WRITEBACK : state <= FETCH; 
            default : state <= FETCH;
        endcase
    end

    always_comb begin
        //defs
        pc_write = 1'b0;
        ir_write = 1'b0;
        alu_src_a = 2'b0;
        alu_src = 1'b0;
        alu_op = ALU_ADD;
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        wb_src = 2'd0;
        pc_src = 1'b0;
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
                            3'b000 : alu_op = alu_operation_t'((funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD);
                            3'b111 : alu_op = ALU_AND;
                            3'b110 : alu_op = ALU_OR;
                            3'b100 : alu_op = ALU_XOR;
                            3'b001 : alu_op = ALU_SLL;
                            3'b101 : alu_op = alu_operation_t'((funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL);
                            3'b010 : alu_op = ALU_SLT;
                            3'b011 : alu_op = ALU_SLTU;
                        endcase
                    end
                    OP_ITYPE : begin
                        alu_src = 1'b1; //immediate is operand 2
                        case(funct3)
                            default : alu_op = ALU_ADD;
                            3'b000 : alu_op = ALU_ADD; //addi
                            3'b111 : alu_op = ALU_AND; //andi
                            3'b110 : alu_op = ALU_OR; //ori
                            3'b100 : alu_op = ALU_XOR; //xori
                            3'b010 : alu_op = ALU_SLT; //slti
                            3'b011 : alu_op = ALU_SLTU; //sltiu            
                            3'b001 : alu_op = ALU_SLL;
                            3'b101 : alu_op = alu_operation_t'((funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL);
                        endcase
                    end
                    OP_LOAD : begin 
                        alu_src = 1'b1;
                        alu_op = ALU_ADD;
                    end
                    OP_STORE : begin
                        alu_src = 1'b1;
                        alu_op = ALU_ADD;
                    end
                    OP_LUI : begin
                        alu_src_a = 2'd1;
                        alu_src = 1'b1;
                        alu_op = ALU_ADD;
                    end
                    OP_AUIPC : begin
                        alu_src_a = 2'd2;
                        alu_src = 1'b1;
                        alu_op = ALU_ADD;
                    end
                    OP_JTYPE : begin
                        pc_write = 1'b1;    
                        pc_src = 1'b1;
                        alu_src_a = 2'd2;
                        alu_src = 1'b1;
                        alu_op = ALU_ADD;
                    end
                    OP_JALR : begin
                        pc_write = 1'b1;
                        pc_src = 1'b1;
                        alu_src_a = 2'd0;
                        alu_src = 1'b1;

                    end
                endcase
            end
            MEMORY : begin
                alu_src = 1'b1;
                if(opcode == OP_LOAD) mem_read = 1'b1;
                if(opcode == OP_STORE) mem_write = 1'b1;

            end
            WRITEBACK : begin
                reg_write = 1'b1;
                if(opcode == OP_LOAD) begin
                    wb_src = 2'd1;
                    alu_src = 1'b1; //keep byte offset valid for LB/LH extraction
                end
                if(opcode == OP_JTYPE || opcode == OP_JALR) begin
                    wb_src = 2'd2;
                end
            end
        endcase
    end
endmodule
