`timescale 1ns/1ps
// Branch test: all six B-type conditions, taken and not-taken, signed vs
// unsigned traps, a countdown loop with a backward branch, poison slots in
// every skipped position, and canary registers that catch a branch wrongly
// writing its ALU result to the register named by its immediate bits.
// Run via run_tests.sh, or standalone from this directory:
//   iverilog -g2012 -o sim -f filelist.txt top_tb_br.sv
//   cp program_br_test.hex program.hex && vvp sim
//
// program_br_test.hex disassembly:
//   0x00: addi x1, x0, 5
//   0x04: addi x2, x0, 5
//   0x08: addi x3, x0, -1              x3 = FFFFFFFF
//   0x0C: addi x4, x0, 1
//   0x10: addi x8, x0, 8               canary: rd-field of every +8 branch is x8
//   0x14: addi x25, x0, 77             canary: rd-field of the -8 branch is x25
//   0x18: beq  x1, x2, +8   taken      (5 == 5)
//   0x1C: addi x5, x0, 99   POISON
//   0x20: beq  x1, x3, +8   not taken  (5 != -1)
//   0x24: addi x6, x0, 6               x6 = 6
//   0x28: bne  x1, x3, +8   taken
//   0x2C: addi x7, x0, 99   POISON
//   0x30: bne  x1, x2, +8   not taken
//   0x34: addi x20, x0, 20             x20 = 20
//   0x38: blt  x3, x4, +8   taken      (-1 < 1 signed)
//   0x3C: addi x9, x0, 99   POISON
//   0x40: bltu x3, x4, +8   not taken  (FFFFFFFF < 1 unsigned is false)
//   0x44: addi x10, x0, 10             x10 = 10
//   0x48: bge  x1, x2, +8   taken      (5 >= 5, equal operands)
//   0x4C: addi x11, x0, 99  POISON
//   0x50: bge  x3, x4, +8   not taken  (-1 >= 1 signed is false)
//   0x54: addi x12, x0, 12             x12 = 12
//   0x58: bgeu x3, x4, +8   taken      (FFFFFFFF >= 1 unsigned)
//   0x5C: addi x13, x0, 99  POISON
//   0x60: bltu x4, x3, +8   taken      (1 < FFFFFFFF unsigned)
//   0x64: addi x14, x0, 99  POISON
//   0x68: blt  x4, x3, +8   not taken  (1 < -1 signed is false)
//   0x6C: addi x15, x0, 15             x15 = 15
//   0x70: addi x16, x0, 3              loop counter
//   0x74: addi x17, x0, 0              iteration count
//   0x78: addi x17, x17, 1             loop:
//   0x7C: addi x16, x16, -1
//   0x80: bne  x16, x0, -8  -> 0x78    backward branch, 3 iterations
//   0x84: addi x18, x0, 18             x18 = 18 (loop exit)
//   0x88: bgeu x4, x3, +8   not taken  (1 >= FFFFFFFF unsigned is false)
//   0x8C: addi x19, x0, 19             x19 = 19
//   0x90: jal  x0, 0                   halt
module top_tb_br;
    logic clk = 0, reset;
    int fails = 0;
    always #5 clk = ~clk;
    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("br.vcd");
        $dumpvars(0, top_tb_br);
    end

    initial begin
        reset = 1;
        @(posedge clk); @(posedge clk);
        reset = 0;

        // ~41 executed instructions x <=5 cycles; halt loop makes overshoot safe
        repeat (300) @(posedge clk);

        $display("--- branch check ---");
        check_reg(1,  32'd5);
        check_reg(2,  32'd5);
        check_reg(3,  32'hFFFFFFFF);
        check_reg(4,  32'd1);
        check_not(5,  32'd99);          // beq taken
        check_reg(6,  32'd6);           // beq not taken
        check_not(7,  32'd99);          // bne taken
        check_reg(20, 32'd20);          // bne not taken
        check_not(9,  32'd99);          // blt taken (signed)
        check_reg(10, 32'd10);          // bltu not taken (unsigned)
        check_not(11, 32'd99);          // bge taken (equal)
        check_reg(12, 32'd12);          // bge not taken (signed)
        check_not(13, 32'd99);          // bgeu taken (unsigned)
        check_not(14, 32'd99);          // bltu taken (unsigned)
        check_reg(15, 32'd15);          // blt not taken (signed)
        check_reg(16, 32'd0);           // loop counter ran to zero
        check_reg(17, 32'd3);           // loop body ran exactly 3 times
        check_reg(18, 32'd18);          // loop exit fall-through
        check_reg(19, 32'd19);          // bgeu not taken
        check_reg(8,  32'd8);           // canary: no +8 branch wrote to x8
        check_reg(25, 32'd77);          // canary: the -8 branch did not write x25
        if (dut.pc_latch === 32'h00000090)
            $display("PASS: halted at pc = %h", dut.pc_latch);
        else begin
            $display("FAIL: pc = %h (expected 00000090)", dut.pc_latch);
            fails++;
        end

        if (fails == 0) $display("ALL %0d CHECKS PASSED", 22);
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

    task check_not(input int idx, input logic [31:0] poison);
        logic [31:0] actual;
        actual = dut.reg_file_module.registers[idx];
        if (actual !== poison)
            $display("PASS: x%0d untouched (poison not executed)", idx);
        else begin
            $display("FAIL: x%0d = %0d -- poison executed, branch went the wrong way", idx, actual);
            fails++;
        end
    endtask
endmodule
