`timescale 1ns/1ps
module top_tb;
    logic clk = 0;
    logic reset;
    always #5 clk = ~clk;

    top dut (.CLK100MHZ(clk), .reset(reset));

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, top_tb);
    end

    initial begin
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        $display("cyc| state | rs1 rs2 rd | rdA      rdB      | imm      | op1      op2      | alu_res  | Rwr | alu_op");
        repeat (16) begin
            @(posedge clk);
            #1;
            $display("   |   %0d   |  %0d   %0d   %0d |%h %h |%h |%h %h |%h |  %b  | %0d",
                dut.cu_module.state,
                dut.rs1, dut.rs2, dut.rd,
                dut.read_data_a, dut.read_data_b,
                dut.immediate,
                dut.operand_1, dut.operand_2,
                dut.alu_res,
                dut.reg_write,
                dut.alu_op);
        end

        $display("--- register check ---");
        check_reg(1, 32'd5);
        check_reg(2, 32'd7);
        check_reg(3, 32'd12);
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
