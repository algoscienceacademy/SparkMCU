# ============================================================================
# SparkMCU - AVR-Compatible Microcontroller on SkyWater 130nm
# ============================================================================

```
  ____                   _    __  __  ____ _   _ 
 / ___| _ __   __ _ _ __| | _|  \/  |/ ___| | | |
 \___ \| '_ \ / _` | '__| |/ / |\/| | |   | | | |
  ___) | |_) | (_| | |  |   <| |  | | |___| |_| |
 |____/| .__/ \__,_|_|  |_|\_\_|  |_|\____|\___/ 
       |_|                                        
```

An open-source **AVR-architecture 8-bit microcontroller** clone designed for
fabrication on **SkyWater 130nm** technology using the **OpenLane** ASIC flow.

## 🏗️ Architecture Overview

SparkMCU implements a subset of the **ATmega328P** instruction set architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                      SparkMCU SoC                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    AVR CPU Core                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌───────────────────────┐  │  │
│  │  │ Register │  │   ALU    │  │  Instruction Decoder  │  │  │
│  │  │  File    │  │  8-bit   │  │   (ATmega328P ISA)    │  │  │
│  │  │ 32x8-bit │  │          │  │                       │  │  │
│  │  └──────────┘  └──────────┘  └───────────────────────┘  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌───────────────────────┐  │  │
│  │  │   PC     │  │   SP     │  │   SREG (Flags)        │  │  │
│  │  │  16-bit  │  │  16-bit  │  │ I T H S V N Z C      │  │  │
│  │  └──────────┘  └──────────┘  └───────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│              ┌───────────┼───────────┐                         │
│              │    Data Bus (8-bit)   │                          │
│              └───────────┼───────────┘                         │
│                          │                                      │
│  ┌────────┐  ┌────────┐  │  ┌────────┐  ┌─────────────────┐   │
│  │ Flash  │  │  SRAM  │  │  │  GPIO  │  │  Interrupt Ctrl │   │
│  │ 32KB*  │  │  2KB*  │  │  │ B,C,D  │  │  INT0/1, PCINT  │   │
│  └────────┘  └────────┘  │  └────────┘  └─────────────────┘   │
│                          │                                      │
│  ┌────────┐  ┌────────┐  │  ┌────────┐                        │
│  │  UART  │  │  SPI   │  │  │Timer/  │                        │
│  │ USART0 │  │ Master │  │  │Counter0│                        │
│  └────────┘  └────────┘  │  └────────┘                        │
│                          │                                      │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                    Physical Pins
```

## 📁 Project Structure

```
SparkMCU/
├── rtl/                          # RTL source files
│   ├── core/                     # CPU core
│   │   ├── spark_pkg.v           # Global defines & parameters
│   │   ├── spark_alu.v           # Arithmetic Logic Unit
│   │   ├── spark_regfile.v       # 32x8 Register File
│   │   ├── spark_decoder.v       # Instruction Decoder
│   │   └── spark_cpu.v           # CPU pipeline controller
│   ├── memory/                   # Memory subsystem
│   │   ├── spark_pmem.v          # Program Memory (Flash ROM)
│   │   ├── spark_dmem.v          # Data Memory (SRAM)
│   │   └── spark_bus_ctrl.v      # Bus controller / memory mapper
│   ├── peripherals/              # I/O peripherals
│   │   ├── spark_gpio.v          # GPIO Port (B, C, D)
│   │   ├── spark_uart.v          # UART (USART0)
│   │   ├── spark_spi.v           # SPI Master/Slave
│   │   ├── spark_timer0.v        # 8-bit Timer/Counter 0
│   │   └── spark_intctrl.v       # Interrupt Controller
│   └── spark_mcu_top.v           # Top-level SoC integration
├── testbench/
│   └── spark_mcu_tb.v            # Comprehensive testbench
├── firmware/                     # Sample AVR firmware
│   ├── blink.S                   # Assembly LED blink
│   └── uart_echo.c              # C UART echo program
├── openlane/                     # OpenLane ASIC flow
│   └── spark_mcu_top/
│       ├── config.tcl            # OpenLane configuration (Tcl)
│       ├── config.json           # OpenLane configuration (JSON)
│       ├── pin_order.cfg         # Pin placement
│       └── constraint.sdc        # Timing constraints
├── Makefile                      # Build system
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

## 🛠️ Features

### CPU Core
- **ISA**: AVR (ATmega328P compatible subset)
- **Data width**: 8-bit
- **Address space**: 16-bit (64KB)
- **Pipeline**: Multi-cycle (Fetch → Decode → Execute → Memory → Writeback)
- **Registers**: 32 general-purpose 8-bit registers (R0-R31)
- **Pointer registers**: X (R27:R26), Y (R29:R28), Z (R31:R30)
- **Stack**: Hardware stack in SRAM, 16-bit stack pointer

### Supported Instructions
| Category | Instructions |
|----------|-------------|
| Arithmetic | ADD, ADC, SUB, SBC, SUBI, SBCI, INC, DEC, NEG, MUL |
| Logic | AND, ANDI, OR, ORI, EOR, COM |
| Compare | CP, CPC, CPI, CPSE |
| Branch | RJMP, RCALL, RET, RETI, JMP, CALL, IJMP, ICALL |
| Conditional | BRBS, BRBC (BREQ, BRNE, BRCS, BRCC, etc.) |
| Data Transfer | MOV, MOVW, LDI, LD, LDD, ST, STD, LDS, STS, LPM |
| Bit | LSR, LSL, ASR, ROR, ROL, SWAP, BST, BLD |
| Stack | PUSH, POP |
| I/O | IN, OUT, SBI, CBI, SBIC, SBIS |
| Skip | SBRC, SBRS, CPSE |
| SREG | BSET, BCLR (SEC, CLC, SEI, CLI, etc.) |
| System | NOP, SLEEP, WDR |

### Peripherals
- **GPIO**: 3 ports (B: 8-bit, C: 6-bit, D: 8-bit) with pin change interrupts
- **UART**: Full-duplex, configurable baud rate, 5-9 data bits, parity, interrupts
- **SPI**: Master mode, configurable CPOL/CPHA, 4 prescaler settings
- **Timer0**: 8-bit, Normal/CTC/Fast PWM/Phase-Correct PWM, 2 compare units
- **Interrupts**: 21 vectors, priority-encoded, INT0/INT1 edge/level detect

### Memory Map (ATmega328P Compatible)
| Address Range | Description |
|--------------|-------------|
| 0x0000-0x001F | Register File (R0-R31) |
| 0x0020-0x005F | I/O Registers (64 addresses) |
| 0x0060-0x00FF | Extended I/O Registers |
| 0x0100-0x08FF | SRAM window in architecture |

\* Current ASIC build configuration uses reduced memory for PnR convergence:
- Program memory: 256 words (16-bit)
- Data SRAM: 128 bytes

## 🚀 Getting Started

### Prerequisites

```bash
# Simulation tools
sudo apt install iverilog gtkwave

# OpenLane (for ASIC flow)
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane
make
make pdk

# AVR toolchain (for firmware)
sudo apt install gcc-avr avr-libc
```

### Run Simulation

```bash
# Run the testbench
make sim

# View waveforms
make wave
```

### Run OpenLane ASIC Flow

```bash
# From the OpenLane root directory
make mount

# Inside the Docker container
./flow.tcl -design SparkMCU/openlane/spark_mcu_top
```

### Compile Firmware

```bash
# Assembly
avr-as -mmcu=atmega328p -o firmware/blink.o firmware/blink.S
avr-ld -o firmware/blink.elf firmware/blink.o
avr-objcopy -O ihex firmware/blink.elf firmware/blink.hex

# C
avr-gcc -mmcu=atmega328p -Os -o firmware/uart_echo.elf firmware/uart_echo.c
avr-objcopy -O ihex firmware/uart_echo.elf firmware/uart_echo.hex
```

## 🎯 Target Technology

| Parameter | Value |
|-----------|-------|
| **Process** | SkyWater 130nm (sky130A) |
| **Std Cell Library** | sky130_fd_sc_hd |
| **Target Clock** | 16 MHz (62.5 ns period) |
| **Supply Voltage** | 1.8V |

## 📊 ASIC Implementation Results

Successfully completed full OpenLane flow (synthesis → signoff) with the following results:

### Floorplan & Placement
| Metric | Value |
|--------|-------|
| **Die Area** | ~969 µm × 980 µm (~0.95 mm²) |
| **Core Utilization** | 35.7% |
| **Target Density** | 40% |
| **Cell Count** | 29,548 standard cells |
| **Tapcells** | 12,213 (FP_TAPCELL_DIST = 14) |
| **Floorplan Sizing** | Relative (auto-computed from utilization) |

### Routing
| Metric | Value |
|--------|-------|
| **Total Wirelength** | 1,658,260 µm |
| **Total Vias** | 273,811 |
| **Routing Congestion** | 29.70% overall usage, 0 overflow |
| **DRT Violations** | 0 (converged at iteration 35) |

### Signoff
| Check | Result |
|-------|--------|
| **Magic DRC** | ✅ **0 errors** |
| **LVS (Netgen)** | ✅ **Circuits match uniquely** |
| **Antenna Check** | ✅ Pass (with diode insertion strategy 4) |

### Key OpenLane Configuration

```tcl
# Floorplan — auto-sized from utilization target
set ::env(FP_SIZING) "relative"
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.40
set ::env(CELL_PAD) 6

# Tapcell — sky130 default spacing
set ::env(FP_TAPCELL_DIST) 14

# Clock
set ::env(CLOCK_PERIOD) "62.5"   ;# 16 MHz

# Routing
set ::env(ROUTING_CORES) 4
set ::env(GRT_ADJUSTMENT) 0.15
set ::env(GRT_ALLOW_CONGESTION) 1
```

## 🔧 Changelog

### 2026-03-24 — Config Fixes for PnR Convergence

Fixed two critical issues that prevented the OpenLane flow from completing:

1. **`FP_TAPCELL_DIST`: 2 → 14** — The original value of 2 µm inserted
   828,920 tapcells (vs 29,548 design cells), overwhelming the detailed placer.
   Changed to 14 µm (sky130 default), reducing tapcells to 12,213.

2. **`FP_SIZING`: absolute → relative** — The hardcoded 3200×3200 µm die area
   resulted in only 4.44% utilization (vs 35% target). Switched to relative
   sizing so OpenLane auto-computes the die area from the utilization target,
   producing a properly-sized ~969×980 µm die.

3. **`CELL_PAD`: 4 → 6** — Slightly increased cell padding for better
   detailed placement legalization.

## 📜 License

This project is open-source hardware, released under the Apache 2.0 License.

## 🙏 Acknowledgments

- [SkyWater PDK](https://github.com/google/skywater-pdk) by Google/SkyWater
- [OpenLane](https://github.com/The-OpenROAD-Project/OpenLane) by Efabless
- [AVR Architecture](https://www.microchip.com/en-us/products/microcontrollers-and-microprocessors/8-bit-mcus/avr-mcus) by Microchip/Atmel
