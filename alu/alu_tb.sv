`timescale 1ns/1ps
import alu_ops::*;

module alu_tb;
    logic [31:0] operand_1, operand_2;
    alu_operation_t operation;
    logic [31:0] result;
    logic zero;

    rv32i_alu dut(
        .operand_1(operand_1), .operand_2(operand_2), 
        .operation(operation), 
        .result(result), 
        .zero(zero)
    );

    task tester(input alu_operation_t op, input logic [31:0] a, b, expected, expected_z);
        operand_1 = a;
        operand_2 = b;
        operation = op;
        #10;
        if(result === expected && zero === expected_z) $display("PASS: op = %0d; %b op %b = %b. (ZERO = %d)", op, a, b, result, zero);
        else $display("FAIL: op = %0d; %b op %b = %b. EXPECTED: %b. (ZERO = %d; EXCPECTED: %d)", op, a, b, result, expected, zero, expected_z);
    endtask

    initial begin
        //basic
        tester(ALU_ADD,  32'd1, 32'd24, 32'd25, 0);
        tester(ALU_SUB,  32'd4, 32'd1, 32'd3, 0);
        tester(ALU_AND,  32'd15, 32'd31, 32'd15, 0);
        tester(ALU_OR,   32'd63, 32'd31, 32'd63, 0);
        tester(ALU_XOR,  32'd21, 32'd42, 32'd63, 0);
        tester(ALU_SLL,  32'd32, 32'd3, 32'd256, 0);
        tester(ALU_SRL,  32'd32, 32'd3, 32'd4, 0);
        tester(ALU_SRA,  32'd15, 32'd2, 32'd3, 0);
        tester(ALU_SRA,  -32'd5, 32'd3, -32'd1, 0);
        tester(ALU_SLT,  -32'd120391, -32'd4566, 32'd1, 0);
        tester(ALU_SLT,  -32'd56, 32'd56, 32'd1, 0);
        tester(ALU_SLT,  32'd65, 32'd32, 32'd0, 1);
        tester(ALU_SLT,  32'd78, -32'd78, 32'd0, 1);
        tester(ALU_SLT,  -32'd1, 32'd1, 32'd1, 0);   
        tester(ALU_SLTU, 32'd1912933, 32'd21314, 32'd0, 1);
        tester(ALU_SLTU, -32'd1, 32'd1, 32'd0, 1);  
        $finish;
    end
endmodule