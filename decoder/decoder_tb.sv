`timescale 1ns/1ps
module decoder_tb;
    logic [31:0] instr;
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] immediate;

    riscv32i_decoder dut(
        .instr(instr),
        .opcode(opcode),
        .rd(rd), .rs1(rs1), .rs2(rs2),
        .funct3(funct3), .funct7(funct7),
        .immediate(immediate)
    );

    task check_imm(input string name, input logic [31:0] in, input logic [31:0] expected);
        instr = in;
        #1;
        if(immediate === expected) $display("PASS: %s  instr=%h  imm=%h", name, in, immediate);
        else $display("FAIL: %s  instr=%h  imm=%h (expected %h)", name, in, immediate, expected);
    endtask

    initial begin
        check_imm("I-type ADDI +5",  32'b000000000101_00000_000_00001_0010011, 32'd5);

        check_imm("I-type ADDI -1",  32'b111111111111_00000_000_00001_0010011, 32'hFFFFFFFF);

        check_imm("I-type LW +8",    32'b000000001000_00001_010_00010_0000011, 32'd8);

        check_imm("S-type SW +12",   32'b0000000_00010_00001_010_01100_0100011, 32'd12);

        check_imm("S-type SW -4",    32'b1111111_00010_00001_010_11100_0100011, 32'hFFFFFFFC);

        check_imm("B-type BEQ +8",   32'b0000000_00010_00001_000_01000_1100011, 32'd8);

        check_imm("U-type LUI",      {20'h12345, 5'b00001, 7'b0110111}, 32'h12345000);

        check_imm("J-type JAL +16",  {1'b0, 10'b0000001000, 1'b0, 8'b00000000, 5'b00001, 7'b1101111}, 32'd16);

        check_imm("R-type ADD (no imm)", 32'b0000000_00010_00001_000_00011_0110011, 32'd0);

        $finish;
    end
endmodule