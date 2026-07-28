import alu_ops::*;
import opcodes::*;
module top(
    input logic CLK100MHZ,
    input logic reset
);
    //control unit
    opcode_t opcode;
    alu_operation_t alu_op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic pc_write, ir_write, alu_src, reg_write;

    riscv32i_control_unit cu_module(
        .CLK100MHZ(CLK100MHZ),
        .reset(reset),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .reg_write(reg_write)
    );

    //registers.
    logic [31:0] read_data_a, read_data_b;
    riscv32i_register_file reg_file_module(
        .CLK100MHZ(CLK100MHZ),
        .read_addr_a(rs1), .read_addr_b(rs2),
        .write_addr(rd),
        .write_data(alu_res),
        .write_en(reg_write),
        .read_data_a(read_data_a), .read_data_b(read_data_b)
    );

    riscv32i_instruction_register instr_reg_module(
        .CLK100MHZ(CLK100MHZ),
        .ir_write(ir_write),
        .instr_in(instr),
        .instr_out(instr_out)
    );

    //fetch --> pc wires to instr mem. then advance pc and latch the instruction in im.
    logic [31:0] next_pc, pc, instr, instr_out;

    assign next_pc = 32'd4 + pc;
    riscv32i_program_counter pc_module(
        .CLK100MHZ(CLK100MHZ), 
        .reset(reset), 
        .pc_write(pc_write), 
        .next_pc(next_pc), 
        .pc(pc)
    );

    riscv32i_instruction_memory instr_mem_module(
        .CLK100MHZ(CLK100MHZ),
        .addr(pc),
        .instr(instr)
    );
    

    //decode
    logic [4:0] rd, rs1, rs2;
    logic[31:0] immediate;
    riscv32i_decoder decoder_module(
        .instr(instr_out),
        .opcode(opcode),
        .rd(rd), .rs1(rs1), .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7),
        .immediate(immediate)
    );

    //execute
    logic[31:0] operand_1, operand_2, alu_res;
    assign operand_1 = read_data_a;
    assign operand_2 = alu_src ? immediate : read_data_b;
    rv32i_alu alu_module(
        .operand_1(operand_1), .operand_2(operand_2),
        .operation(alu_op),
        .result(alu_res)
    );

    //writeback done
endmodule