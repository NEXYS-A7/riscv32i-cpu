`timescale 1ns/1ps
module data_memory_tb;
    logic        clk = 0;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic        write_en;
    logic [31:0] read_data;

    always #5 clk = ~clk;

    riscv32i_data_memory dut (
        .CLK100MHZ(clk),
        .addr(addr),
        .write_data(write_data),
        .write_en(write_en),
        .read_data(read_data)
    );

    task write_mem(input logic [31:0] byte_addr, input logic [31:0] data);
        addr       = byte_addr;
        write_data = data;
        write_en   = 1'b1;
        @(posedge clk);     // write lands here
        #1;
        write_en   = 1'b0;
    endtask

    task read_check(input logic [31:0] byte_addr, input logic [31:0] expected);
        addr = byte_addr;
        @(posedge clk);    
        #1;
        if (read_data === expected)
            $display("PASS: addr %0d (word %0d) = %h", byte_addr, byte_addr>>2, read_data);
        else
            $display("FAIL: addr %0d (word %0d) = %h (expected %h)", byte_addr, byte_addr>>2, read_data, expected);
    endtask

    initial begin
        write_en = 0; addr = 0; write_data = 0;
        #1;

        write_mem(32'd0, 32'hAAAA0000);
        read_check(32'd0, 32'hAAAA0000);

        write_mem(32'd4, 32'hBBBB1111);
        read_check(32'd4, 32'hBBBB1111);

        write_mem(32'd8, 32'hCCCC2222);
        read_check(32'd8, 32'hCCCC2222);

        read_check(32'd0, 32'hAAAA0000);
        read_check(32'd4, 32'hBBBB1111);

        addr = 32'd0; write_data = 32'hDEADDEAD; write_en = 1'b0;
        @(posedge clk); #1;
        read_check(32'd0, 32'hAAAA0000);   // unchanged

        //overwrite an existing location
        write_mem(32'd4, 32'h12345678);
        read_check(32'd4, 32'h12345678);

        write_mem(32'd12, 32'h33334444);
        read_check(32'd12, 32'h33334444);
        read_check(32'd13, 32'h33334444); 
        $finish;
    end
endmodule