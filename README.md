# Pipelined MIPS32 Processor in Verilog

This repository contains the Verilog source code for a behavioral model of a 5-stage pipelined MIPS32 processor. The design implements a subset of the MIPS32 instruction set architecture, including R-type, I-type, branch, and halt instructions. The project includes the core processor module (`MIPS32.v`) and several testbenches to verify its functionality for various programs.

---

## Features

* **5-Stage Pipeline:** The processor follows the classic 5-stage RISC pipeline:
    1.  **IF (Instruction Fetch)**
    2.  **ID (Instruction Decode & Register Fetch)**
    3.  **EX (Execute)**
    4.  **MEM (Memory Access)**
    5.  **WB (Write Back)**
* [cite_start]**Two-Phase Clocking:** The pipeline stages are synchronized using a two-phase clock (`clk1`, `clk2`)[cite: 14, 15].
* **Instruction Set:** A foundational set of MIPS instructions is supported.
* **Hazard Management:**
    * [cite_start]**Branch Hazards:** The pipeline is flushed upon a taken branch to ensure correct program flow[cite: 24].
    * [cite_start]**Data Hazards:** Data hazards are currently handled by inserting `NOP` (no-operation) instructions (implemented as `OR R_x, R_x, R_x`) into the instruction stream within the testbenches to create the necessary stalls[cite: 6].

---

## Implemented Instruction Set

The processor supports the following MIPS instructions:

| Type      | Mnemonics                               | Opcodes        |
| :-------- | :-------------------------------------- | :------------- |
| **R-Type**| `ADD`, `SUB`, `AND`, `OR`, `SLT`, `MUL` | `000000` - `000101` |
| **I-Type**| `ADDI`, `SUBI`, `SLTI`                  | `001010` - `001100` |
| **Memory**| `LW` (Load Word), `SW` (Store Word)     | `001000`, `001001` |
| **Branch**| `BEQZ`, `BNEQZ`                         | `001110`, `001101` |
| **Jump** | `J`                                     | `010000`       |
| **System**| `HLT` (Halt)                            | `111111`       |

---

## File Structure

* [cite_start]`MIPS32.v`: The core behavioral Verilog module for the 5-stage pipelined processor[cite: 14].
* [cite_start]`addition_tb.v`: Testbench for verifying `ADD` and `ADDI` instructions[cite: 71].
* [cite_start]`test_load_add_store_tb.v`: Testbench for a sequence of `LW`, `ADDI`, and `SW` instructions[cite: 1].
* [cite_start]`test_factorial_tb.v`: A comprehensive testbench to calculate factorial, testing `LW`, `MUL`, `SUBI`, and `BNEQZ` instructions[cite: 54].

---

## Getting Started

### Prerequisites

You will need the following tools to compile and simulate the project:
* **Icarus Verilog (`iverilog`)**: For compiling the Verilog source files.
* **GTKWave**: For visualizing the waveform output (`.vcd` files).

### Running a Simulation

1.  **Compile the Verilog Files**: Open a terminal and navigate to the project directory. Use the `iverilog` command to compile the main MIPS module along with a testbench.
    ```shell
    iverilog -o <output_filename> MIPS32.v <testbench_file.v>
    ```
    *Example:*
    ```shell
    iverilog -o mips_add.vvp MIPS32.v addition_tb.v
    ```

2.  **Run the Simulation**: Execute the compiled file using `vvp`.
    ```shell
    vvp <output_filename>
    ```
    *Example:*
    ```shell
    vvp mips_add.vvp
    ```

3.  **View the Waveform**: The simulation will generate a `.vcd` file. Open this file with GTKWave to analyze the signals.
    ```shell
    gtkwave <dumpfile_name.vcd>
    ```
    *Example:*
    ```shell
    gtkwave mips_add.vcd
    ```

---





