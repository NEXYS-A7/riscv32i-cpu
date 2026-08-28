`timescale 1ns/1ps
// U-type test: LUI and AUIPC, including the lui/addi hi-lo carry trick and
// AUIPC at non-zero addresses (catches reading the already-advanced PC).
// Run via run_tests.sh, or standalone from this directory:
//   iverilog -g2012 -o sim -f filelist.txt top_tb_ui.sv
//   cp program_ui_test.hex program.hex && vvp sim
//
// program_ui_test.hex disassembly:
//   0x00: lui   x1, 0x7FFF8       x1 = 7FFF8000
//   0x04: addi  x2, x1, 0x081     x2 = 7FFF8081  (same constant as mem test, 2 instrs instead of 7)
//   0x08: auipc x3, 0x12          x3 = 0x08 + 12000 = 00012008
//   0x0C: lui   x4, 0xFFFFF       x4 = FFFFF000  (top bit set)
//   0x10: addi  x5, x4, -1        x5 = FFFFEFFF
//   0x14: auipc x6, 0             x6 = 00000014  (just the instruction's own address)
//   0x18: lui   x7, 0xDEADC       x7 = DEADC000  (hi part bumped +1 because lo is negative)
//   0x1C: addi  x7, x7, -273      x7 = DEADBEEF
//   0x20: auipc x8, 0xFFFFF       x8 = 0x20 + FFFFF000 = FFFFF020 (negative offset)
module top_tb_ui;
    logic clk = 0, reset;
    int fails = 0;
    always #5 clk = ~clk;
    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("ui.vcd");
        $dumpvars(0, top_tb_ui);
    end

    initial begin
        reset = 1;
        @(posedge clk); @(posedge clk);
        reset = 0;

        // 9 instructions x 4 cycles = 36, give margin
        repeat (80) @(posedge clk);

        $display("--- LUI / AUIPC check ---");
        check_reg(1, 32'h7FFF8000);   // lui
        check_reg(2, 32'h7FFF8081);   // lui + addi
        check_reg(3, 32'h00012008);   // auipc at 0x08
        check_reg(4, 32'hFFFFF000);   // lui with bit 31 set
        check_reg(5, 32'hFFFFEFFF);   // addi -1 on it
        check_reg(6, 32'h00000014);   // auipc with zero imm = own address
        check_reg(7, 32'hDEADBEEF);   // lui/addi with hi/lo carry correction
        check_reg(8, 32'hFFFFF020);   // auipc with negative offset

        if (fails == 0) $display("ALL %0d CHECKS PASSED", 8);
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
