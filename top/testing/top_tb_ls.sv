`timescale 1ns/1ps
module top_tb;
    logic clk = 0, reset;
    always #5 clk = ~clk;
    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, top_tb);
    end

    initial begin
        reset = 1;
        @(posedge clk); @(posedge clk);
        reset = 0;

        // 7 instructions x ~5 cycles = ~35, give margin
        repeat (50) @(posedge clk);

        $display("--- load/store check ---");
        check_reg(1, 32'd42);   // x1 = 42
        check_reg(2, 32'd64);   // x2 = 64
        check_reg(3, 32'd42);   // x3 = LW result = 42
        check_reg(4, 32'd42);   // x4 = LB result = 42
        check_reg(5, 32'd42);   // x5 = LBU result = 42
        $finish;
    end

    task check_reg(input int idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = dut.reg_file_module.registers[idx];
        if (actual === expected)
            $display("PASS: x%0d = %0d", idx, actual);
        else
            $display("FAIL: x%0d = %h (expected %0d)", idx, actual, expected);
    endtask
endmodule