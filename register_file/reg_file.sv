module riscv32i_register_file #(
    input logic CLK100MHZ, 
    input logic [4:0] read_addr_a, [4:0] read_addr_b,
    input logic [4:0] write_addr,
    input logic [31:0] write_data,
    input logic write_en,
    output logic [31:0] read_data_a, read_data_b
);
    
endmodule