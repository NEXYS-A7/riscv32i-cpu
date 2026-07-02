module riscv32i_instruction_memory(
    input logic CLK100MHZ,
    input logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [0:1023]; //4 x 1024 

    always_ff @(posedge CLK100MHZ) begin : clk_read
        instr <= mem[addr[11:2]];
    end

    initial begin
        $readmemh("program.hex", mem);
    end
endmodule