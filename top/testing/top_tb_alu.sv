`timescale 1ns/1ps
// Full ALU instruction test: every implemented I-type and R-type op, plus x0 write protection.
// Run via run_tests.sh, or standalone from this directory:
//   iverilog -g2012 -o sim -f filelist.txt top_tb_alu.sv
//   cp program_alu_test.hex program.hex && vvp sim
//
// program_alu_test.hex disassembly:
//   addi x1, x0, 100      x1 = 100
//   addi x2, x1, -50      x2 = 50
//   andi x3, x1, 68       x3 = 68
//   ori  x4, x1, 3        x4 = 103
//   xori x5, x1, -1       x5 = ~100 = 0xFFFFFF9B
//   slti x6, x2, 60       x6 = 1
//   slti x7, x2, -60      x7 = 0
//   sltiu x8, x2, 60      x8 = 1
//   sltiu x9, x5, 1       x9 = 0
//   slli x10, x1, 3       x10 = 800
//   srli x11, x5, 24      x11 = 255
//   srai x12, x5, 4       x12 = 0xFFFFFFF9
//   add  x13, x1, x2      x13 = 150
//   sub  x14, x2, x1      x14 = -50 = 0xFFFFFFCE
//   and  x15, x1, x3      x15 = 68
//   or   x16, x1, x3      x16 = 100
//   xor  x17, x1, x3      x17 = 32
//   addi x18, x0, 2       x18 = 2
//   sll  x19, x1, x18     x19 = 400
//   srl  x20, x5, x18     x20 = 0x3FFFFFE6
//   sra  x21, x5, x18     x21 = 0xFFFFFFE6
//   slt  x22, x2, x1      x22 = 1
//   slt  x23, x1, x5      x23 = 0
//   sltu x24, x1, x5      x24 = 1
//   addi x0, x0, 99       x0 must stay 0
//   add  x25, x0, x0      x25 = 0 (reads x0 after the write attempt)
module top_tb_alu;
    logic clk = 0, reset;
    int fails = 0;
    always #5 clk = ~clk;
    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("alu_full.vcd");
        $dumpvars(0, top_tb_alu);
    end

    initial begin
        reset = 1;
        @(posedge clk); @(posedge clk);
        reset = 0;

        // 26 instructions x 4 cycles = 104, give margin
        repeat (160) @(posedge clk);

        $display("--- ALU instruction check ---");
        check_reg(1,  32'd100);        // addi
        check_reg(2,  32'd50);         // addi negative imm
        check_reg(3,  32'd68);         // andi
        check_reg(4,  32'd103);        // ori
        check_reg(5,  32'hFFFFFF9B);   // xori (bitwise not)
        check_reg(6,  32'd1);          // slti taken
        check_reg(7,  32'd0);          // slti not taken
        check_reg(8,  32'd1);          // sltiu
        check_reg(9,  32'd0);          // sltiu vs large unsigned
        check_reg(10, 32'd800);        // slli
        check_reg(11, 32'd255);        // srli
        check_reg(12, 32'hFFFFFFF9);   // srai
        check_reg(13, 32'd150);        // add
        check_reg(14, 32'hFFFFFFCE);   // sub
        check_reg(15, 32'd68);         // and
        check_reg(16, 32'd100);        // or
        check_reg(17, 32'd32);         // xor
        check_reg(18, 32'd2);          // addi (shift amount)
        check_reg(19, 32'd400);        // sll
        check_reg(20, 32'h3FFFFFE6);   // srl
        check_reg(21, 32'hFFFFFFE6);   // sra
        check_reg(22, 32'd1);          // slt taken
        check_reg(23, 32'd0);          // slt signed compare
        check_reg(24, 32'd1);          // sltu same operands
        check_reg(25, 32'd0);          // x0 read after write attempt

        if (dut.reg_file_module.registers[0] === 32'd99) begin
            $display("FAIL: write to x0 landed in the register file");
            fails++;
        end else
            $display("PASS: x0 write blocked");

        if (fails == 0) $display("ALL %0d CHECKS PASSED", 26);
        else            $display("%0d CHECKS FAILED", fails);
        $finish;
    end

    task check_reg(input int idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = dut.reg_file_module.registers[idx];
        if (actual === expected)
            $display("PASS: x%0d = %h", idx, actual);
        else begin
            $display("FAIL: x%0d = %h (expected %h)", idx, actual, expected);
            fails++;
        end
    endtask
endmodule
