import alu_ops::*;
import opcodes::*;
module top(
    input logic CLK100MHZ,
    input logic reset
);
    //signal declarations (all up front: SystemVerilog requires declare-before-use
    //control
    opcode_t opcode;
    alu_operation_t alu_op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [1:0] alu_src_a, wb_src, pc_src;
    logic pc_write, ir_write, alu_src, reg_write, mem_read, mem_write, zero, alu_lsb;

    //fetch
    logic [31:0] next_pc, pc, instr, instr_out, pc_latch, branch_target;

    //decode
    logic [4:0] rd, rs1, rs2;
    logic [31:0] immediate;
    logic [31:0] read_data_a, read_data_b;

    //execute
    logic [31:0] operand_1, operand_2, alu_res, alu_result_register;

    //memory
    logic [3:0] byte_en;
    logic [31:0] store_data;
    logic [1:0] byte_offset;
    logic [31:0] mem_read_data, load_res;
    logic [7:0] load_byte;
    logic [15:0] load_half;

    //writeback
    logic [31:0] writeback_data, link_value;

    //---------------------------------------------------------------
    //control unit
    riscv32i_control_unit cu_module(
        .CLK100MHZ(CLK100MHZ),
        .reset(reset),
        .opcode(opcode),
        .immediate(immediate),
        .funct3(funct3),
        .funct7(funct7),
        .zero(zero),
        .alu_lsb(alu_lsb),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .alu_src_a(alu_src_a),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .wb_src(wb_src),
        .pc_src(pc_src)
    );

    //registers.
    riscv32i_register_file reg_file_module(
        .CLK100MHZ(CLK100MHZ),
        .read_addr_a(rs1), .read_addr_b(rs2),
        .write_addr(rd),
        .write_data(writeback_data),
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
    assign branch_target = pc_latch + immediate;
    assign next_pc = (pc_src == 2'd2) ? branch_target : (pc_src == 2'd1) ? {alu_res[31:1], 1'b0} : pc + 32'd4;
    riscv32i_program_counter pc_module(
        .CLK100MHZ(CLK100MHZ),
        .reset(reset),
        .pc_write(pc_write),
        .next_pc(next_pc),
        .pc(pc)
    );

    always_ff @(posedge CLK100MHZ) begin
        if(ir_write) pc_latch <= pc;
    end

    riscv32i_instruction_memory instr_mem_module(
        .CLK100MHZ(CLK100MHZ),
        .addr(pc),
        .instr(instr)
    );


    //decode
    riscv32i_decoder decoder_module(
        .instr(instr_out),
        .opcode(opcode),
        .rd(rd), .rs1(rs1), .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7),
        .immediate(immediate)
    );

    //execute
    assign operand_1 = alu_src_a == 2'd1 ? 32'd0 : alu_src_a == 2'd2 ? pc_latch : read_data_a;
    assign operand_2 = alu_src ? immediate : read_data_b;

    always_ff @(posedge CLK100MHZ) begin
        alu_result_register <= alu_res;
    end

    rv32i_alu alu_module(
        .operand_1(operand_1), .operand_2(operand_2),
        .operation(alu_op),
        .result(alu_res),
        .zero(zero),
        .alu_lsb(alu_lsb)
    );

    //memory
    assign byte_offset = alu_result_register[1:0];
    always_comb begin
        byte_en = 4'b0000;
        store_data = read_data_b;
        case(funct3)
            3'b000 : begin //SB
                byte_en = 4'b0001 << byte_offset;
                store_data = read_data_b << (8 * byte_offset);
            end
            3'b001 : begin
                byte_en = 4'b0011 << byte_offset;
                store_data = read_data_b << (8 * byte_offset);
            end
            3'b010 : begin
                byte_en = 4'b1111;
                store_data = read_data_b;
            end
            default : begin
                byte_en = 4'b0000;
                store_data = read_data_b;
            end
        endcase
    end

    assign load_byte = mem_read_data[8*byte_offset +: 8];
    assign load_half = mem_read_data[16*alu_result_register[1] +: 16];

    always_comb begin
        case(funct3)
            3'b000 : load_res = {{24{load_byte[7]}}, load_byte}; //lb
            3'b001 : load_res = {{16{load_half[15]}}, load_half}; //lh
            3'b010 : load_res = mem_read_data; //lw
            3'b100 : load_res = {24'd0, load_byte}; //lbu
            3'b101 : load_res = {16'd0, load_half}; //lhu
            default : load_res = mem_read_data;
        endcase
    end

    riscv32i_data_memory data_mem_module(
        .CLK100MHZ(CLK100MHZ),
        .addr(alu_result_register),
        .write_data(store_data),
        .byte_en(byte_en),
        .write_en(mem_write),
        .read_data(mem_read_data)
    );


    //writeback done
    assign link_value = pc_latch + 32'd4;
    always_comb begin
        case(wb_src)
            2'd1 : writeback_data = load_res;
            2'd2 : writeback_data = link_value;
            default : writeback_data = alu_result_register;
        endcase
    end

endmodule
