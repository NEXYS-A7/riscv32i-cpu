#!/bin/bash
# Run every CPU test: module-level unit testbenches, then full-system programs.
# Usage (from anywhere, needs iverilog/vvp on PATH):  bash run_tests.sh
# Build artifacts go to testing/build/, one subdir per test (sim binary, program.hex, vcd).
cd "$(dirname "$0")" || exit 1
fail=0

run_unit() { # name, sources..., run_dir(last arg is dir to vvp from, "." = build dir)
    local name=$1; shift
    mkdir -p "build/$name"; rm -f "build/$name/sim"
    echo "=== unit: $name ==="
    iverilog -g2012 -o "build/$name/sim" "$@" 2>&1 | grep -v "sorry:"
    if [ ! -f "build/$name/sim" ]; then echo "COMPILE FAILED"; fail=1; return; fi
    out=$(cd "build/$name" && vvp sim)
    echo "$out" | grep -v -e "VCD info" -e "WARNING"
    echo "$out" | grep -q FAIL && fail=1
}

run_system() { # name, testbench, program hex
    local name=$1 tb=$2 hex=$3
    mkdir -p "build/$name"; rm -f "build/$name/sim"
    echo "=== system: $name ==="
    iverilog -g2012 -o "build/$name/sim" -f filelist.txt "$tb" 2>&1 | grep -v "sorry:"
    if [ ! -f "build/$name/sim" ]; then echo "COMPILE FAILED"; fail=1; return; fi
    cp "$hex" "build/$name/program.hex"
    out=$(cd "build/$name" && vvp sim)
    echo "$out" | grep -v -e "VCD info" -e "WARNING"
    echo "$out" | grep -q FAIL && fail=1
}

R=../..
run_unit alu       $R/alu/alu_ops.sv $R/alu/alu.sv $R/alu/alu_tb.sv
run_unit decoder   $R/decoder/opcodes.sv $R/decoder/decoder.sv $R/decoder/decoder_tb.sv
run_unit pc        $R/pc/pc.sv $R/pc/pc_tb.sv
run_unit reg_file  $R/register_file/reg_file.sv $R/register_file/reg_file_tb.sv
run_unit data_mem  $R/memory/data/data_mem.sv $R/memory/data/data_mem_tb.sv

# instruction memory tb reads its own program.hex from the run dir
mkdir -p build/instr_mem && cp $R/memory/instruction/program.hex build/instr_mem/program.hex
run_unit instr_mem $R/memory/instruction/instruction_mem.sv $R/memory/instruction/instruction_mem_tb.sv

run_system basic  top_tb.sv     program_basic_test.hex
run_system ls     top_tb_ls.sv  program_ls_test.hex
run_system alu    top_tb_alu.sv program_alu_test.hex
run_system mem    top_tb_mem.sv program_mem_test.hex
run_system ui     top_tb_ui.sv  program_ui_test.hex
run_system jal    top_tb_jal.sv program_jal_test.hex
run_system br     top_tb_br.sv  program_br_test.hex

echo
if [ $fail -eq 0 ]; then echo "ALL TEST SUITES PASSED"; else echo "SOME TESTS FAILED"; exit 1; fi
