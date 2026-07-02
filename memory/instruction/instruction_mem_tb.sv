`timescale 1ns/1ps
module instruction_memory_tb;
    logic        clk = 0;
    logic [31:0] addr;
    logic [31:0] instr;

    always #5 clk = ~clk;

    riscv32i_instruction_memory dut (
        .CLK100MHZ(clk),
        .addr(addr),
        .instr(instr)
    );

    task fetch_check(input logic [31:0] byte_addr, input logic [31:0] expected);
        addr = byte_addr;
        @(posedge clk);   
        #1;
        if (instr === expected)
            $display("PASS: addr %0d (word %0d) -> %h", byte_addr, byte_addr>>2, instr);
        else
            $display("FAIL: addr %0d (word %0d) -> %h (expected %h)", byte_addr, byte_addr>>2, instr, expected);
    endtask

    initial begin
        addr = 0;
        #1;


        fetch_check(32'd0,  32'hDEADBEEF);    
        fetch_check(32'd4,  32'h11112222); 
        fetch_check(32'd8,  32'h33334444);  
        fetch_check(32'd12, 32'hCAFEBABE); 
        fetch_check(32'd16, 32'h00000001);  
        fetch_check(32'd20, 32'hFFFFFFFF);  
        fetch_check(32'd24, 32'h12345678);  
        fetch_check(32'd28, 32'hA5A5A5A5);   

        fetch_check(32'd5,  32'h11112222);  

        fetch_check(32'd12, 32'hCAFEBABE);  
        $finish;
    end
endmodule