`timescale 1ns/1ps
module top_tb;
    logic clk = 0;
    logic reset;

    always #5 clk = ~clk;

    top dut (
        .CLK100MHZ(clk),
        .reset(reset)
    );

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, top_tb);
    end

    initial begin
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        // print signals each cycle to see what's happening
        $display("cycle |    pc    |   instr   | instr_out | state | rd | reg_write");
        repeat (25) begin
            @(posedge clk);
            #1;
            $display("      | %h | %h | %h |   %0d   | %0d  |    %b",
                dut.pc, dut.instr, dut.instr_out, dut.cu_module.state, dut.rd, dut.reg_write);
        end

        $display("--- register check ---");
        check_reg(1, 32'd5);
        check_reg(2, 32'd7);
        check_reg(3, 32'd12);
        $display("--- done ---");
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
