`timescale 1ns/1ps
// Jump test: JAL forward/backward, plain j (rd=x0), JALR through a register,
// call/return pattern, JALR bit-0 clearing, and a jump-to-self halt.
// "Poison" instructions sit in skipped slots: if any executes, the jump failed.
// Run via run_tests.sh, or standalone from this directory:
//   iverilog -g2012 -o sim -f filelist.txt top_tb_jal.sv
//   cp program_jal_test.hex program.hex && vvp sim
//
// program_jal_test.hex disassembly:
//   0x00: addi  x1, x0, 5           x1 = 5
//   0x04: jal   x2, +12  -> 0x10    x2 = 0x08 (link)
//   0x08: addi  x3, x0, 99          POISON (skipped)
//   0x0C: addi  x4, x0, 99          POISON (skipped)
//   0x10: jal   x0, +20  -> 0x24    plain j, no link
//   0x14: addi  x5, x0, 7           "function f": x5 = 7      <- only reached by the call at 0x24
//   0x18: jalr  x0, 0(x11)          ret (back to 0x28)
//   0x1C: addi  x6, x0, 99          POISON (after ret)
//   0x20: addi  x7, x0, 99          POISON (skipped by j)
//   0x24: jal   x11, -16 -> 0x14    call f, backward jump, x11 = 0x28 (link)
//   0x28: addi  x8, x0, 8           x8 = 8 (return lands here)
//   0x2C: auipc x9, 0               x9 = 0x2C
//   0x30: jalr  x10, 13(x9)         target 0x39 -> bit 0 cleared -> 0x38, x10 = 0x34 (link)
//   0x34: addi  x12, x0, 99         POISON (skipped)
//   0x38: addi  x13, x0, 13         x13 = 13
//   0x3C: jal   x0, 0               halt (jump to self)
module top_tb_jal;
    logic clk = 0, reset;
    int fails = 0;
    always #5 clk = ~clk;
    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("jal.vcd");
        $dumpvars(0, top_tb_jal);
    end

    initial begin
        reset = 1;
        @(posedge clk); @(posedge clk);
        reset = 0;

        // 11 executed instructions x ~4 cycles; halt loop makes overshoot safe
        repeat (120) @(posedge clk);

        $display("--- JAL / JALR check ---");
        check_reg(1,  32'd5);
        check_reg(2,  32'h00000008);   // jal link = addr of jal + 4
        check_not(3,  32'd99);         // poison after first jal
        check_not(4,  32'd99);
        check_reg(5,  32'd7);          // function body ran
        check_not(6,  32'd99);         // poison after ret
        check_not(7,  32'd99);         // poison skipped by plain j
        check_reg(11, 32'h00000028);   // backward jal link
        check_reg(8,  32'd8);          // return landed at 0x28
        check_reg(9,  32'h0000002C);   // auipc
        check_reg(10, 32'h00000034);   // jalr link
        check_not(12, 32'd99);         // poison skipped by jalr
        check_reg(13, 32'd13);
        if (dut.pc_latch === 32'h0000003C)
            $display("PASS: halted at pc = %h (jalr bit 0 cleared)", dut.pc_latch);
        else begin
            $display("FAIL: pc = %h (expected 0000003c; 0000003d means jalr did not clear bit 0)", dut.pc_latch);
            fails++;
        end

        if (fails == 0) $display("ALL %0d CHECKS PASSED", 14);
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
            $display("FAIL: x%0d = %0d -- poison instruction executed, jump missed", idx, actual);
            fails++;
        end
    endtask
endmodule
