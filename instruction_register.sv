module riscv32i_instruction_register(
    input logic CLK100MHZ,
    input logic ir_write,
    input logic [31:0] instr_in,
    output logic [31:0] instr_out
);
    always_ff(@posedge CLK100MHZ) begin
        if(ir_write) instr_out <= instr_in;
    end
endmodule