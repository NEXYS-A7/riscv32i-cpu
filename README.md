# riscv32i-cpu

a multicycle rv32i cpu written from scratch in systemverilog. targets the digilent nexys a7 (artix-7 100t). the full base integer isa is implemented and tested: all 37 computational instructions plus fence/ecall/ebreak decoded as no-ops.

this is the first step of a longer project. the plan is multicycle -> pipelined -> run compiled c over uart -> eventually no-mmu linux on the board's ddr2. the multicycle core exists so there's a known-good reference to check the pipeline against.

## how it works

every instruction walks through a small fsm in the control unit: fetch, decode, execute, and then memory and/or writeback depending on the opcode. alu ops and jumps take 4 cycles, loads take 5, stores and branches take 4.

the datapath is the usual set of parts wired together in `top/top.sv`:

- `pc/` program counter with a write enable
- `memory/instruction/` synchronous-read instruction rom, loaded from `program.hex`
- `instruction_register.sv` holds the fetched instruction (and `pc_latch` remembers where it came from, which auipc/jal/branches need since the pc has already advanced)
- `decoder/` pulls out rd/rs1/rs2/funct3/funct7 and builds the sign-extended immediate for all six formats
- `register_file/` 32 x 32, two async read ports, one sync write port, x0 hardwired to zero
- `alu/` add/sub/and/or/xor/sll/srl/sra/slt/sltu, plus a zero flag and result lsb that feed back into the control unit for branches
- `memory/data/` synchronous byte-addressable ram with byte enables, so sb/sh/sw and lb/lh/lw/lbu/lhu all work at any offset
- `control_unit/` the fsm and all the mux selects

a couple of design notes that took some debugging to get right:

- the instruction memory is synchronous, so after a jump or taken branch the pc needs one spare cycle before fetch latches the new instruction. that's why branches go through writeback even though they write nothing.
- branches are the only place data flows backwards into the controller. the alu's zero/lsb outputs come back in as inputs and `pc_write` is computed from them combinationally within the execute cycle.
- jalr clears bit 0 of the target like the spec says. the instruction memory ignores the low bits anyway, but the pc register would drift by one otherwise and every pc-relative value after it would be wrong.

## running the tests

you need icarus verilog (`brew install icarus-verilog` on mac, or the windows installer). then

```
bash top/testing/run_tests.sh
```

that compiles and runs every unit testbench (alu, decoder, pc, register file, both memories) and then six system-level programs against the full cpu. each program is hand-assembled hex with a matching self-checking testbench that reads the register file at the end:

- `basic` addi/addi/add sanity check
- `ls` the original load/store smoke test
- `alu` every i-type and r-type op, plus a write to x0 that has to be ignored
- `mem` every load and store variant at every byte offset, sign extension both ways
- `ui` lui and auipc, including the hi/lo carry trick for negative low halves
- `jal` jal and jalr forward and backward, call/return, link values, the bit-0 clear
- `br` all six branches taken and not-taken, signed vs unsigned traps, a countdown loop

skipped-over slots in the jump and branch programs hold "poison" instructions that write 99 to a register, so a jump that doesn't happen shows up as a specific register being wrong instead of a silent pass. the testbench headers have a disassembly of each program.

build output goes to `top/testing/build/` and is gitignored.

## layout

```
alu/                alu + ops package + unit tb
control_unit/       fsm control unit
decoder/            field/immediate decoder + opcode package + unit tb
memory/data/        data ram + unit tb
memory/instruction/ instruction rom + unit tb
pc/                 program counter + unit tb
register_file/      register file + unit tb
top/                top-level cpu, nexys a7 constraints, program.hex
top/testing/        system testbenches, test programs, run_tests.sh
```

## whats next

- c toolchain flow: linker script, crt0, objcopy to hex, run compiled programs in sim
- memory-mapped uart so programs can print
- pipeline it (5 stage, forwarding, hazard detection)
- m extension, then csrs and traps, then the long road to linux
