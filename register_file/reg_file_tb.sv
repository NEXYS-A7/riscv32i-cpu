`timescale 1ns/1ps
module regfile_tb;
    //signals to connect to the register file
    logic        clk = 0;
    logic [4:0]  read_addr_a, read_addr_b, write_addr;
    logic [31:0] write_data, read_data_a, read_data_b;
    logic        write_en;

    //clock generator: toggles every 5ns -> 10ns period (100MHz)
    always #5 clk = ~clk;

    //instantiate the device under test
    riscv32i_register_file dut (
        .CLK100MHZ(clk),
        .read_addr_a(read_addr_a), .read_addr_b(read_addr_b),
        .write_addr(write_addr), .write_data(write_data),
        .write_en(write_en),
        .read_data_a(read_data_a), .read_data_b(read_data_b)
    );

    task write_reg(input logic [4:0] addr, input logic [31:0] data);
        write_addr = addr;
        write_data = data;
        write_en   = 1'b1;
        @(posedge clk);   
        #1;                 
        write_en   = 1'b0;  
    endtask

    task check_a(input logic [4:0] addr, input logic [31:0] expected);
        read_addr_a = addr;
        #1;           
        if (read_data_a === expected)
            $display("PASS: reg[%0d] port A = %h", addr, read_data_a);
        else
            $display("FAIL: reg[%0d] port A = %h (expected %h)", addr, read_data_a, expected);
    endtask

    task check_both(input logic [4:0] addr_a, addr_b,
                    input logic [31:0] exp_a, exp_b);
        read_addr_a = addr_a;
        read_addr_b = addr_b;
        #1;
        if (read_data_a === exp_a && read_data_b === exp_b)
            $display("PASS: port A reg[%0d]=%h, port B reg[%0d]=%h",
                     addr_a, read_data_a, addr_b, read_data_b);
        else
            $display("FAIL: port A reg[%0d]=%h (exp %h), port B reg[%0d]=%h (exp %h)",
                     addr_a, read_data_a, exp_a, addr_b, read_data_b, exp_b);
    endtask

    initial begin
        // init
        write_en = 0; write_addr = 0; write_data = 0;
        read_addr_a = 0; read_addr_b = 0;
        #1;

        write_reg(5'd5, 32'hDEADBEEF);
        check_a(5'd5, 32'hDEADBEEF);

        write_reg(5'd7, 32'h12345678);
        check_both(5'd5, 5'd7, 32'hDEADBEEF, 32'h12345678);

        check_a(5'd0, 32'd0);

        write_reg(5'd0, 32'hFFFFFFFF);
        check_a(5'd0, 32'd0);

        write_addr = 5'd5; write_data = 32'hAAAAAAAA; write_en = 1'b0;
        @(posedge clk); #1;
        check_a(5'd5, 32'hDEADBEEF);   

        write_reg(5'd5, 32'hCAFEBABE);
        check_a(5'd5, 32'hCAFEBABE);

        check_both(5'd5, 5'd5, 32'hCAFEBABE, 32'hCAFEBABE);

        $finish;
    end
endmodule