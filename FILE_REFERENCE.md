# SparkMCU Verification Framework: Complete File Reference

## Overview

This document provides a complete reference of all files in the firmware-driven verification framework, their purposes, dependencies, and how they interact.

---

## Directory Structure & File Manifest

```
SparkMCU/
│
├── 📄 QUICKSTART.md                 [YOU START HERE - 5 min guide]
├── 📄 README-VERIFICATION.md         [Implementation summary]
├── 📄 SETUP.md                      [Tool installation guide]
├── 📄 VERIFICATION_FLOW.md          [Complete detailed guide]
├── 📄 ARCHITECTURE.md               [Design & internals]
├── 📄 FILE_REFERENCE.md             [This file]
│
├── 🔨 Makefile.fw                   [Build automation]
├── 🔨 build_firmware.sh             [Firmware build script]
├── 🔨 simulate.sh                   [Simulation launcher script]
│
├── 📁 firmware/
│   ├── 📁 src/
│   │   ├── 🆕 test_suite_main.c         [MAIN - Comprehensive test suite]
│   │   ├── ✅ uart_echo_main.c          [Existing - UART echo demo]
│   │   ├── ✅ blink_main.c              [Existing - LED blink]
│   │   ├── ✅ led_toggle_main.c         [Existing - LED toggle]
│   │   ├── ✅ timer_demo_main.c         [Existing - Timer demo]
│   │   └── ✅ startup.S                 [Existing - Startup code]
│   │
│   ├── 📁 include/
│   │   ├── 🆕 test_framework.h          [NEW - Test framework library]
│   │   └── ✅ spark_mcu.h               [Device register definitions]
│   │
│   ├── 📁 lib/
│   │   ├── ✅ delay.c                   [Delay functions]
│   │   ├── ✅ gpio.c                    [GPIO utilities]
│   │   ├── ✅ timer.c                   [Timer utilities]
│   │   └── ✅ uart.c                    [UART utilities]
│   │
│   ├── 📁 build/                       [Generated files]
│   │   ├── test_suite_main.o           [Compiled object]
│   │   ├── test_suite_main.elf         [Linked executable]
│   │   ├── test_suite_main.hex         [Intel HEX format]
│   │   ├── spark_mcu.vvp               [Simulation binary]
│   │   ├── spark_mcu.lxt               [Waveform output]
│   │   └── spark_mcu_test.vcd          [VCD dump (opt)]
│   │
│   ├── 📁 scripts/
│   │   └── ✅ linker.ld                 [Linker script]
│   │
│   └── 📄 Makefile                      [Firmware build]
│
├── 📁 rtl/
│   ├── ✅ spark_mcu_top.v              [Top-level SoC]
│   │
│   ├── 📁 core/
│   │   ├── ✅ spark_cpu.v              [CPU core]
│   │   ├── ✅ spark_alu.v              [Arithmetic Logic Unit]
│   │   ├── ✅ spark_decoder.v          [Instruction decoder]
│   │   ├── ✅ spark_regfile.v          [Register file]
│   │   └── ✅ spark_pkg.v              [Package definitions]
│   │
│   ├── 📁 memory/
│   │   ├── ✅ spark_pmem.v             [Original program memory]
│   │   ├── 🆕 spark_flash_rom.v        [NEW - Flash ROM with $readmemh]
│   │   ├── ✅ spark_dmem.v             [Data memory (SRAM)]
│   │   └── ✅ spark_bus_ctrl.v         [Bus controller]
│   │
│   └── 📁 peripherals/
│       ├── ✅ spark_gpio.v             [GPIO controller]
│       ├── ✅ spark_uart.v             [UART interface]
│       ├── ✅ spark_timer0.v           [8-bit Timer/Counter]
│       ├── ✅ spark_intctrl.v          [Interrupt controller]
│       └── ✅ spark_spi.v              [SPI master/slave]
│
├── 📁 testbench/
│   ├── ✅ spark_mcu_tb.v               [Original low-level testbench]
│   └── 🆕 spark_mcu_test_tb.v          [NEW - Enhanced with UART monitor]
│
└── 📁 openlane/
    └── [OpenLane synthesis files - not part of verification]
```

---

## New Files Created (🆕 marker)

### 1. Core Framework

#### `firmware/include/test_framework.h`
- **Type**: C Header Library
- **Purpose**: Test framework utilities and macros
- **Contents**:
  - UART initialization and transmission
  - Test case management (start, assert, end)
  - Test result reporting
  - GPIO, Timer, and memory utilities
  - Delay functions

**Key Exports:**
```c
void test_init(void);
void test_start(const char *name);
void test_assert(uint8_t condition, const char *msg);
void test_end(void);
void test_report(void);

void uart_init(void);
void uart_puts(const char *str);
void uart_put_hex(uint8_t val);

void gpio_init_outputs(void);
void gpio_write_byte(uint8_t port, uint8_t value);
uint8_t gpio_read_byte(uint8_t port);

void timer0_init(uint8_t prescaler);
uint8_t timer0_read(void);
void timer0_write(uint8_t value);
uint8_t timer0_overflow_flag(void);
void timer0_clear_overflow_flag(void);
void delay_ms(uint16_t ms);
```

**Dependencies**: None (standard C + avr-libc)

**Used By**:
- `firmware/src/test_suite_main.c`
- Any custom test files


#### `firmware/src/test_suite_main.c`
- **Type**: C Source File
- **Purpose**: Comprehensive test suite with 14 test cases
- **Function**: Main entry point for verification

**Test Cases Included:**
1. GPIO Port B read/write
2. GPIO Port C read/write (6-bit)
3. GPIO Port D read/write
4. Timer0 basic operation
5. Timer0 overflow
6. UART loopback
7. ALU addition
8. ALU subtraction
9. ALU AND operation
10. ALU OR operation
11. ALU XOR operation
12. SPI communication
13. External interrupt INT0
14. Memory read/write

**Output Format:**
- UART text output with PASS/FAIL for each test
- Final summary with pass/fail counts
- Exits with infinite loop

**Dependencies**:
- `firmware/include/test_framework.h`
- `avr/io.h`, `avr/interrupt.h`

**Used By**:
- Makefile.fw (via build system)
- simulate.sh


### 2. RTL Modules

#### `rtl/memory/spark_flash_rom.v`
- **Type**: Verilog RTL Module
- **Purpose**: Program memory with $readmemh hex file loading
- **Function**: Bridge between compiled hex files and RTL simulation

**Key Features:**
- Parametrized memory depth (default 16K x 16-bit)
- $readmemh initialization
- Synchronous read port (fetch)
- Debug/monitor read port
- Programming write port (optional)

**Parameters:**
```verilog
parameter DEPTH = 16384      // 16K words (32KB)
parameter AW = 14           // Address width
parameter HEX_FILE = ""     // Path to hex file
```

**Ports:**
```verilog
// CPU fetch interface
input  wire [AW-1:0] fetch_addr
output wire [15:0]   fetch_data
input  wire          fetch_en

// Debug port
input  wire [AW-1:0] monitor_addr
output wire [15:0]   monitor_data
input  wire          monitor_en

// Programming port
input  wire [AW-1:0] prog_addr
input  wire [15:0]   prog_data
input  wire          prog_we
```

**Used By**:
- `spark_mcu_top.v` (replaces spark_pmem)
- `testbench/spark_mcu_test_tb.v`


### 3. Testbench

#### `testbench/spark_mcu_test_tb.v`
- **Type**: Verilog Testbench
- **Purpose**: Enhanced testbench with UART monitoring and test result capture
- **Function**: Orchestrates complete firmware-driven verification

**Key Components:**

1. **Clock & Reset Generation**
   - 16 MHz clock generation (62.5 ns period)
   - Power-on reset simulation

2. **DUT Instantiation**
   - Instantiates `tt_um_spark_mcu_top`
   - Connects all I/O signals

3. **UART Monitor**
   - Synchronous UART receiver logic
   - Baud rate: 9600 (configurable)
   - Frame format: START + 8 DATA + STOP
   - Character decoding and display

4. **Test Result Parser**
   - Detects "PASS" and "FAIL" keywords
   - Aggregates test counts
   - Generates final report

5. **Timeout Monitor**
   - Prevents infinite simulation hangs
   - Configurable simulation time

**Parameters:**
```verilog
parameter CLK_PERIOD = 62.5        // 16 MHz
parameter UART_BAUD = 9600         // Baud rate
parameter HEX_FILE = "firmware/build/test.hex"
parameter SIM_TIME = 100000000     // 100ms max
```

**Output:**
- Console text output (simulation log)
- PASS/FAIL counts
- Test status (PASSED/FAILED)
- Optional VCD/LXT waveform files

**Dependencies**:
- `spark_mcu_top.v` (DUT)
- All RTL modules in `rtl/`
- Hex file from firmware compilation

**Used By**:
- Simulation scripts
- Makefile


### 4. Build System

#### `Makefile.fw`
- **Type**: GNU Makefile
- **Purpose**: Automation for firmware build and simulation
- **Function**: Central build automation

**Targets:**
```makefile
make -f Makefile.fw build-fw       # Build firmware
make -f Makefile.fw simulate       # Run simulation
make -f Makefile.fw verify         # Build + simulate
make -f Makefile.fw clean          # Clean artifacts
make -f Makefile.fw help           # Show help
```

**Key Features:**
- Automatic tool invocation (avr-gcc, iverilog)
- Dependency tracking
- Build artifact management
- Configurable test name and parameters

**Configuration Variables:**
```makefile
MCU = atmega328p
F_CPU = 16000000UL
OPTIMIZER = -Os
SIMULATOR = iverilog
TEST_NAME ?= test_suite_main
```

**Dependencies**:
- `avr-gcc`, `avr-objcopy`, `avr-size`
- `iverilog`, `vvp`
- C source files in `firmware/src/`
- Verilog files in `rtl/` and `testbench/`

**Generates**:
- Hex files
- Simulation binaries
- Waveform outputs


#### `build_firmware.sh`
- **Type**: Bash Shell Script
- **Purpose**: Standalone firmware compilation
- **Function**: Alternative to Makefile for building only

**Usage:**
```bash
./build_firmware.sh test_suite_main
./build_firmware.sh uart_echo_main
```

**Operations Performed:**
1. Validates avr-gcc availability
2. Compiles C source to object file
3. Links object files to ELF
4. Converts ELF to Intel HEX
5. Reports build statistics

**Output Files:**
- `.o` object file
- `.elf` executable
- `.hex` hex file

**Dependencies**:
- `avr-gcc`, `avr-objcopy`, `avr-size`


#### `simulate.sh`
- **Type**: Bash Shell Script
- **Purpose**: Standalone simulation execution
- **Function**: Alternative to Makefile for running simulation

**Usage:**
```bash
./simulate.sh iverilog test_suite_main
./simulate.sh [simulator] [test_name]
```

**Supported Simulators:**
- iverilog (implemented)
- vivado (framework ready)
- modelsim (framework ready)
- vcs (framework ready)

**Operations Performed:**
1. Validates hex file exists
2. Validates simulator availability
3. Compiles RTL with simulator
4. Runs simulation
5. Reports results

**Dependencies**:
- Hex file from `build_firmware.sh`
- `iverilog`, `vvp`
- RTL and testbench files


### 5. Documentation Files

#### `QUICKSTART.md`
- **Target Audience**: First-time users
- **Time Required**: 5 minutes
- **Content**: Minimal steps to get running
- **Scope**: Quick start and common commands

#### `README-VERIFICATION.md`
- **Target Audience**: Project overview
- **Time Required**: 10 minutes
- **Content**: Summary of implementation
- **Scope**: What was delivered and how to use it

#### `SETUP.md`
- **Target Audience**: System administrators
- **Time Required**: 30 minutes
- **Content**: Tool installation and environment setup
- **Scope**: Complete installation guide for all platforms

#### `VERIFICATION_FLOW.md`
- **Target Audience**: Verification engineers
- **Time Required**: 1-2 hours
- **Content**: Complete usage guide
- **Scope**: All features, usage patterns, debugging

#### `ARCHITECTURE.md`
- **Target Audience**: Hardware architects
- **Time Required**: 1-2 hours
- **Content**: Design and implementation details
- **Scope**: How each component works, timing, integration

#### `FILE_REFERENCE.md`
- **Target Audience**: Developers
- **Time Required**: 30 minutes
- **Content**: Detailed file-by-file reference
- **Scope**: Every file's purpose, dependencies, interactions

---

## File Dependency Graph

```
Firmware Compilation Path:
────────────────────────────
firmware/src/test_suite_main.c
   └→ firmware/include/test_framework.h
       └→ avr/io.h, avr/interrupt.h (system)
   
   └→ [avr-gcc compile]
   
   └→ firmware/build/test_suite_main.o
   
   └→ [avr-gcc link]
   
   └→ firmware/build/test_suite_main.elf
   
   └→ [avr-objcopy convert]
   
   └→ firmware/build/test_suite_main.hex


Simulation Path:
────────────────
firmware/build/test_suite_main.hex
   └→ $readmemh in spark_flash_rom.v
   
   └→ rtl/memory/spark_flash_rom.v
       └→ rtl/spark_mcu_top.v
           └→ rtl/core/*.v (CPU, ALU)
           └→ rtl/memory/*.v (SRAM, Bus)
           └→ rtl/peripherals/*.v (GPIO, UART, Timer, SPI, Interrupts)
   
   └→ testbench/spark_mcu_test_tb.v
       └→ Instantiates DUT
       └→ Monitors UART
       └→ Captures results
   
   └→ [iverilog compile]
   
   └→ firmware/build/spark_mcu.vvp
   
   └→ [vvp execute]
   
   └→ Simulation output
   └→ firmware/build/spark_mcu.lxt


Tool Chain Dependencies:
────────────────────────
avr-gcc, avr-objcopy, avr-size
   ↓
Firmware binary (ELF/HEX)
   ↓
iverilog, vvp
   ↓
HDL simulation
```

---

## Interaction Matrix

| File A | Interacts With | Type | Reason |
|--------|---|------|--------|
| test_suite_main.c | test_framework.h | include | Uses test API |
| test_suite_main.c | spark_cpu.v | indirect | Executed by |
| test_framework.h | spark_mcu.h | include | Register defs |
| build_firmware.sh | test_suite_main.c | process | Compiles |
| Makefile.fw | build_firmware.sh | calls | Automates |
| Makefile.fw | simulate.sh | calls | Automates |
| simulate.sh | spark_flash_rom.v | loads | Hex file |
| spark_mcu_test_tb.v | spark_flash_rom.v | instantiates | Memory |
| spark_mcu_test_tb.v | spark_mcu_top.v | instantiates | DUT |
| spark_mcu_top.v | spark_flash_rom.v | instantiates | Program mem |
| spark_mcu_top.v | All rtl/core/*.v | instantiates | Core logic |
| spark_mcu_top.v | All rtl/peripherals/*.v | instantiates | I/O |

---

## Build Output Artifacts

### After `build_firmware.sh test_suite_main`:

```
firmware/build/
├── test_suite_main.o            [~5 KB]   Object file
├── test_suite_main.elf          [~10 KB]  Executable
└── test_suite_main.hex          [~8 KB]   Intel HEX format
```

### After `simulate.sh iverilog test_suite_main`:

```
firmware/build/
├── spark_mcu.vvp                [~2 MB]   Compiled simulation
├── spark_mcu.lxt                [~100 KB] LXT waveform (optional)
└── spark_mcu_test.vcd           [~200 KB] VCD waveform (if enabled)
```

---

## Configuration Points

### Changeable Parameters

1. **Clock Frequency** (`testbench/spark_mcu_test_tb.v`)
   ```verilog
   parameter CLK_PERIOD = 62.5;  // For 16 MHz
   ```

2. **UART Baud Rate**
   ```c
   // firmware/include/test_framework.h
   #define UART_BAUD 9600
   
   // testbench/spark_mcu_test_tb.v
   parameter UART_BAUD = 9600;
   ```

3. **Simulation Time**
   ```makefile
   # Makefile.fw
   SIM_TIME = 100000000  # ns
   ```

4. **MCU Type & F_CPU**
   ```makefile
   MCU = atmega328p
   F_CPU = 16000000UL
   ```

5. **Test Name**
   ```bash
   make -f Makefile.fw TEST_NAME=my_test
   ```

---

## Version Control Recommendations

### Files to Track

```
firmware/src/*.c           # Track
firmware/include/*.h       # Track
rtl/**/*.v                 # Track
testbench/*.v              # Track
*.sh                       # Track
Makefile*                  # Track
*.md                       # Track
```

### Files to Ignore

```
firmware/build/            # Generated
*.o *.elf *.hex           # Generated
*.vvp *.lxt *.vcd         # Generated
.git                      # VCS
```

### .gitignore Example

```
# Build artifacts
firmware/build/
*.o
*.elf
*.hex
*.vvp
*.lxt
*.vcd

# Editor files
*~
*.swp
.vscode/

# System files
.DS_Store
Thumbs.db
```

---

## File Statistics

| Category | Count | Total Size | Purpose |
|----------|-------|-----------|---------|
| C Source | 1 new + 5 existing | ~15 KB | Firmware |
| C Headers | 1 new + 1 existing | ~8 KB | Definitions |
| Verilog RTL | 1 new + 14 existing | ~200 KB | Hardware |
| Verilog TB | 1 new + 1 existing | ~10 KB | Testing |
| Build Files | 3 new | ~15 KB | Automation |
| Documentation | 6 new | ~100 KB | Guides |
| **Total** | **33 files** | **~358 KB** | **Complete System** |

---

## Integration Checklist

- [x] ✅ Flash ROM module (spark_flash_rom.v)
- [x] ✅ Test framework header (test_framework.h)
- [x] ✅ Test suite source (test_suite_main.c)
- [x] ✅ Enhanced testbench (spark_mcu_test_tb.v)
- [x] ✅ Build automation (Makefile.fw)
- [x] ✅ Build script (build_firmware.sh)
- [x] ✅ Simulation script (simulate.sh)
- [x] ✅ Quick start guide (QUICKSTART.md)
- [x] ✅ Setup guide (SETUP.md)
- [x] ✅ Detailed guide (VERIFICATION_FLOW.md)
- [x] ✅ Architecture document (ARCHITECTURE.md)
- [x] ✅ Summary document (README-VERIFICATION.md)
- [x] ✅ This reference (FILE_REFERENCE.md)

---

## How to Extend

### Add New Test Case

1. **Write test function** in `firmware/src/test_suite_main.c`
2. **Call in main()** after test_init()
3. **Rebuild**: `make -f Makefile.fw verify`

### Add New RTL Module

1. **Create** `rtl/category/new_module.v`
2. **Instantiate** in `spark_mcu_top.v`
3. **Add to** RTL_SOURCES in Makefile.fw

### Add New Documentation

1. **Create** markdown file in project root
2. **Link** from README-VERIFICATION.md
3. **Reference** in QUICKSTART.md if critical

### Switch Simulators

1. **Edit** simulate.sh to add simulator branch
2. **Implement** compilation and execution
3. **Test** with example

---

## Testing the Setup

### Minimal Test

```bash
# Just verify tools are installed
bash check_setup.sh
```

### Quick Verification

```bash
# Build + simulate (should take <1 minute)
make -f Makefile.fw verify
```

### Full Verification

```bash
# Clean, build, simulate with output
make -f Makefile.fw clean
make -f Makefile.fw build-fw
make -f Makefile.fw simulate
```

---

## Common Tasks Reference

| Task | File | Command |
|------|------|---------|
| Build firmware | test_suite_main.c | `./build_firmware.sh test_suite_main` |
| Run simulation | spark_mcu_test_tb.v | `./simulate.sh iverilog` |
| Add test case | test_suite_main.c | Edit + rebuild |
| Check tools | - | `bash check_setup.sh` |
| View help | Makefile.fw | `make -f Makefile.fw help` |
| Clean builds | build/ | `make -f Makefile.fw clean` |
| Install tools | - | See SETUP.md |
| Quick start | - | See QUICKSTART.md |

---

## File Relationships Graph

```
            ┌─────────────────────┐
            │  BUILD SYSTEM       │
            │                     │
            │  Makefile.fw        │
            │  build_firmware.sh  │
            │  simulate.sh        │
            └──────────┬──────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
    ┌──────────────┐        ┌─────────────────┐
    │ FIRMWARE     │        │ HDL SIMULATION  │
    │              │        │                 │
    │ C Code       │        │ RTL + TB        │
    │ ├─ .c files  │        │ ├─ spark_mcu_*  │
    │ └─ .h files  │        │ ├─ spark_*_*    │
    └──────┬───────┘        │ └─ testbench    │
           │                └────────┬────────┘
           │                         │
           ▼                         ▼
    ┌──────────────┐        ┌─────────────────┐
    │ COMPILATION  │        │ SIMULATION      │
    │              │        │                 │
    │ ELF Binary   │        │ Verilog Binary  │
    │ Hex File     │        │ (vvp)           │
    └──────┬───────┘        └────────┬────────┘
           │                         │
           └─────────────┬───────────┘
                         │
                         ▼
                  ┌─────────────────┐
                  │ TEST RESULTS    │
                  │                 │
                  │ Console Output  │
                  │ PASS/FAIL       │
                  │ Waveforms       │
                  └─────────────────┘
```

---

## Quick Reference Index

| Need | See File | Section |
|------|----------|---------|
| 5-min intro | QUICKSTART.md | Start Here |
| Install tools | SETUP.md | Option 1-4 |
| Complete guide | VERIFICATION_FLOW.md | All |
| Architecture | ARCHITECTURE.md | Components |
| This reference | FILE_REFERENCE.md | (you are here) |
| Quick commands | README-VERIFICATION.md | Quick Start |
| Build system | Makefile.fw | Top of file |
| Test framework | test_framework.h | All |
| Test cases | test_suite_main.c | Main functions |
| Flash ROM | spark_flash_rom.v | All |
| Testbench | spark_mcu_test_tb.v | UART Monitor |

---

**Version**: 1.0 | **Last Updated**: March 2026 | **SparkMCU v1.0**
