`timescale 1ns/1ps
// Full load/store test: SB/SH/SW and LB/LH/LW/LBU/LHU, every byte offset,
// sign extension on bytes/halves with the sign bit both set and clear.
// Run via run_tests.sh, or standalone from this directory:
//   iverilog -g2012 -o sim -f filelist.txt top_tb_mem.sv
//   cp program_mem_test.hex program.hex && vvp sim
//
// program_mem_test.hex disassembly:
//   addi x1, x0, 128            base address
//   x2 = 0x7FFF8081             built via addi/slli (bytes: 81 80 FF 7F)
//   sw  x2, 0(x1)               mem[128] = 7FFF8081
//   lw  x3, 0(x1)               x3 = 7FFF8081
//   lb  x4, 0(x1)               x4 = FFFFFF81 (sign extend 0x81)
//   lbu x5, 0(x1)               x5 = 00000081
//   lb  x6, 1(x1)               x6 = FFFFFF80
//   lbu x7, 1(x1)               x7 = 00000080
//   lb  x8, 3(x1)               x8 = 0000007F (positive byte)
//   lh  x9, 0(x1)               x9 = FFFF8081 (sign extend 0x8081)
//   lhu x10, 0(x1)              x10 = 00008081
//   lh  x11, 2(x1)              x11 = 00007FFF (positive half)
//   lb  x14, 2(x1)              x14 = FFFFFFFF
//   sb  x4, 4(x1)               byte 0x81 -> 132
//   sb  x8, 5(x1)               byte 0x7F -> 133
//   sb  x2, 6(x1)               byte 0x81 -> 134
//   sb  x8, 7(x1)               byte 0x7F -> 135
//   lw  x12, 4(x1)              x12 = 7F817F81
//   sh  x2, 8(x1)               half 0x8081 -> 136
//   sh  x11, 10(x1)             half 0x7FFF -> 138
//   lw  x13, 8(x1)              x13 = 7FFF8081
module top_tb_mem;
    logic clk = 0, reset;
    int fails = 0;
    always #5 clk = ~clk;
    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("mem_full.vcd");
        $dumpvars(0, top_tb_mem);
    end

    initial begin
        reset = 1;
        @(posedge clk); @(posedge clk);
        reset = 0;

        // 27 instructions, loads take 5 cycles: ~125, give margin
        repeat (200) @(posedge clk);

        $display("--- load/store instruction check ---");
        check_reg(1,  32'd128);        // base
        check_reg(2,  32'h7FFF8081);   // pattern built from addi/slli
        check_reg(3,  32'h7FFF8081);   // lw
        check_reg(4,  32'hFFFFFF81);   // lb offset 0, negative byte
        check_reg(5,  32'h00000081);   // lbu offset 0
        check_reg(6,  32'hFFFFFF80);   // lb offset 1, negative byte
        check_reg(7,  32'h00000080);   // lbu offset 1
        check_reg(8,  32'h0000007F);   // lb offset 3, positive byte
        check_reg(9,  32'hFFFF8081);   // lh offset 0, negative half
        check_reg(10, 32'h00008081);   // lhu offset 0
        check_reg(11, 32'h00007FFF);   // lh offset 2, positive half
        check_reg(14, 32'hFFFFFFFF);   // lb offset 2 (0xFF)
        check_reg(12, 32'h7F817F81);   // word rebuilt from four sb
        check_reg(13, 32'h7FFF8081);   // word rebuilt from two sh

        check_mem(32, 32'h7FFF8081);   // sw target (addr 128)
        check_mem(33, 32'h7F817F81);   // sb targets (addr 132..135)
        check_mem(34, 32'h7FFF8081);   // sh targets (addr 136..139)

        if (fails == 0) $display("ALL %0d CHECKS PASSED", 17);
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

    task check_mem(input int word_idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = dut.data_mem_module.mem[word_idx];
        if (actual === expected)
            $display("PASS: mem[%0d] = %h", word_idx, actual);
        else begin
            $display("FAIL: mem[%0d] = %h (expected %h)", word_idx, actual, expected);
            fails++;
        end
    endtask
endmodule
