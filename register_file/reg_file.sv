module riscv32i_register_file (
    input logic CLK100MHZ, 
    input logic [4:0] read_addr_a, read_addr_b,
    input logic [4:0] write_addr,
    input logic [31:0] write_data,
    input logic write_en,
    output logic [31:0] read_data_a, read_data_b
);
    logic [31:0] registers [31:0];
    assign read_data_a = (read_addr_a == 5'd0) ? 32'd0 : registers[read_addr_a];
    assign read_data_b = (read_addr_b == 5'd0) ? 32'd0 : registers[read_addr_b];

    always_ff @(posedge CLK100MHZ) begin : write_logic
        if(write_en && write_addr != 0) registers[write_addr] <= write_data;
    end
endmodule