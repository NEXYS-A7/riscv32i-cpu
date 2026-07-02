`timescale 1ns/1ps
module program_counter_tb;
    logic        clk = 0;
    logic        reset;
    logic        pc_write;
    logic [31:0] next_pc;
    logic [31:0] pc;

    always #5 clk = ~clk;

    riscv32i_program_counter dut(
        .CLK100MHZ(clk),
        .reset(reset),
        .pc_write(pc_write),
        .next_pc(next_pc),
        .pc(pc)
    );

    task check(input string name, input logic [31:0] expected);
        #1;
        if (pc === expected)
            $display("PASS: %s  pc=%h", name, pc);
        else
            $display("FAIL: %s  pc=%h (expected %h)", name, pc, expected);
    endtask

    initial begin
        reset = 1; pc_write = 0; next_pc = 32'd0;
        @(posedge clk);
        check("reset to 0", 32'd0);

        reset = 0; pc_write = 1; next_pc = 32'd4;
        @(posedge clk);
        check("update to 4", 32'd4);

        next_pc = 32'd8;
        @(posedge clk);
        check("update to 8", 32'd8);

        pc_write = 0; next_pc = 32'd100;
        @(posedge clk);
        check("hold at 8 (pc_write low)", 32'd8);

        pc_write = 1; next_pc = 32'hDEADBEEF;
        @(posedge clk);
        check("jump to DEADBEEF", 32'hDEADBEEF);

        reset = 1;
        @(posedge clk);
        check("reset overrides update", 32'd0);

        $finish;
    end
endmodule