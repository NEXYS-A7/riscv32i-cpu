module riscv32i_program_counter(
    input logic CLK100MHZ,
    input logic reset,
    input logic pc_write,
    input logic [31:0] next_pc,
    output logic [31:0] pc
);
    always_ff @(posedge CLK100MHZ) begin 
        if(reset) pc <= 32'd0;
        else if(pc_write) pc <= next_pc;
    end
endmodule
