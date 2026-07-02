module riscv32i_data_memory(
    input logic CLK100MHZ,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    input logic write_en,
    output logic [31:0] read_data 
);
    logic [31:0] mem [0:1023];

    always_ff @(posedge CLK100MHZ) begin : clk_read_or_write
        if(write_en) begin
            mem[addr[11:2]] <= write_data;
        end
        read_data <= mem[addr[11:2]];
    end
endmodule