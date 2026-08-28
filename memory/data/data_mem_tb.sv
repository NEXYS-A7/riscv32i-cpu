`timescale 1ns/1ps
module data_memory_tb;
    logic        clk = 0;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic [3:0]  byte_en;
    logic        write_en;
    logic [31:0] read_data;

    always #5 clk = ~clk;

    riscv32i_data_memory dut (
        .CLK100MHZ(clk),
        .addr(addr),
        .write_data(write_data),
        .byte_en(byte_en),
        .write_en(write_en),
        .read_data(read_data)
    );

    task write_lanes(input logic [31:0] byte_addr, input logic [31:0] data, input logic [3:0] be);
        addr       = byte_addr;
        write_data = data;
        byte_en    = be;
        write_en   = 1'b1;
        @(posedge clk);     // write lands here
        #1;
        write_en   = 1'b0;
        byte_en    = 4'b0000;
    endtask

    task write_mem(input logic [31:0] byte_addr, input logic [31:0] data);
        write_lanes(byte_addr, data, 4'b1111);
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
        write_en = 0; addr = 0; write_data = 0; byte_en = 0;
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

        //partial writes: single byte lane, then halfword lanes
        write_mem(32'd16, 32'hAAAA0000);
        write_lanes(32'd16, 32'h000000EF, 4'b0001);   // SB into lane 0
        read_check(32'd16, 32'hAAAA00EF);
        write_lanes(32'd16, 32'h00005600, 4'b0010);   // SB into lane 1
        read_check(32'd16, 32'hAAAA56EF);
        write_lanes(32'd16, 32'hBEEF0000, 4'b1100);   // SH into upper half
        read_check(32'd16, 32'hBEEF56EF);
        $finish;
    end
endmodule