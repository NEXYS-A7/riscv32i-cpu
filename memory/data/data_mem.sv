module riscv32i_data_memory(
    input logic CLK100MHZ,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    input logic [3:0] byte_en,
    input logic write_en,
    output logic [31:0] read_data 
);
    logic [31:0] mem [0:1023];

    always_ff @(posedge CLK100MHZ) begin : clk_read_or_write
        if(write_en) begin
            if(byte_en[0]) mem[addr[11:2]][7:0] <= write_data[7:0];
            if(byte_en[1]) mem[addr[11:2]][15:8] <= write_data[15:8];
            if(byte_en[2]) mem[addr[11:2]][23:16] <= write_data[23:16];
            if(byte_en[3]) mem[addr[11:2]][31:24] <= write_data[31:24];
        end
        read_data <= mem[addr[11:2]];
    end

endmodule