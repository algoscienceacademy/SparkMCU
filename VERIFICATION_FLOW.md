# SparkMCU Firmware-Driven RTL Verification Flow

## Overview

This document describes the complete firmware-driven verification flow for SparkMCU. The system allows you to compile C firmware with `avr-gcc`, load it into the Verilog testbench via `$readmemh`, simulate the MCU, and verify peripheral functionality by monitoring UART output.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  C Firmware Sources (src/*.c)               │
│                                                             │
│  - test_suite_main.c      (Comprehensive test suite)       │
│  - Individual test modules (can be extended)               │
└─────────────────────────────────┬───────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   avr-gcc Compilation      │
                    │  (Produces .elf file)      │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │  avr-objcopy Conversion    │
                    │  (Produces .hex file)      │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │  Intel HEX Format File     │
                    │  (firmware/build/*.hex)    │
                    └─────────────┬──────────────┘
                                  │
┌─────────────────────────────────▼───────────────────────────┐
│                    Verilog Testbench                        │
│                (testbench/spark_mcu_test_tb.v)              │
│                                                             │
│  1. Loads .hex file via $readmemh                          │
│  2. Instantiates SparkMCU RTL                              │
│  3. Monitors UART_TXD output                               │
│  4. Decodes UART frames                                    │
│  5. Captures test results                                  │
│  6. Generates PASS/FAIL report                             │
└─────────────────────────────────┬───────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   HDL Simulation           │
                    │   (iverilog, VCS, etc.)    │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   Waveform & Results       │
                    │   (.lxt, .vcd files)       │
                    └────────────────────────────┘
```

## Directory Structure

```
SparkMCU/
├── firmware/
│   ├── src/
│   │   ├── test_suite_main.c      # Comprehensive test suite
│   │   ├── led_toggle_main.c      # Simple LED toggle (existing)
│   │   ├── uart_echo_main.c       # UART echo (existing)
│   │   ├── blink_main.c           # Blink test (existing)
│   │   ├── timer_demo_main.c      # Timer demo (existing)
│   │   └── startup.S              # Startup code
│   │
│   ├── include/
│   │   ├── spark_mcu.h            # Device register definitions
│   │   └── test_framework.h       # NEW: Test framework utilities
│   │
│   ├── lib/
│   │   ├── delay.c
│   │   ├── gpio.c
│   │   ├── timer.c
│   │   └── uart.c
│   │
│   ├── build/                     # Build output directory
│   │   ├── test_suite_main.hex    # Generated hex file
│   │   ├── test_suite_main.elf    # Generated ELF file
│   │   └── spark_mcu.vvp          # Generated simulator binary
│   │
│   ├── Makefile                   # Firmware build
│   └── README.md
│
├── rtl/
│   ├── spark_mcu_top.v            # Top-level SoC
│   ├── core/
│   │   ├── spark_cpu.v
│   │   ├── spark_alu.v
│   │   ├── spark_decoder.v
│   │   ├── spark_regfile.v
│   │   └── spark_pkg.v
│   │
│   ├── memory/
│   │   ├── spark_pmem.v           # Original program memory
│   │   ├── spark_flash_rom.v      # NEW: Flash ROM with $readmemh
│   │   ├── spark_dmem.v           # Data memory
│   │   └── spark_bus_ctrl.v       # Bus controller
│   │
│   └── peripherals/
│       ├── spark_gpio.v
│       ├── spark_uart.v
│       ├── spark_timer0.v
│       ├── spark_intctrl.v
│       └── spark_spi.v
│
├── testbench/
│   ├── spark_mcu_tb.v             # Original testbench
│   └── spark_mcu_test_tb.v        # NEW: Enhanced testbench with UART monitor
│
├── Makefile.fw                    # NEW: Firmware verification Makefile
├── build_firmware.sh              # NEW: Build script
├── simulate.sh                    # NEW: Simulation script
└── VERIFICATION_FLOW.md           # This file
```

## Quick Start

### 1. Build Firmware

```bash
# Build default test suite
make -f Makefile.fw build-fw

# Or with custom test
make -f Makefile.fw build-fw TEST_NAME=uart_echo_main

# Or use build script directly
./build_firmware.sh test_suite_main
```

**Output:**
```
[BUILD] SparkMCU Firmware (test_suite_main)
[COMPILE] test_suite_main.c
[OK] Compilation successful
[LINK] Creating ELF file
[OK] Linking successful
[HEX] Converting to Intel HEX format
[OK] Hex conversion successful
[STATS]
ELF file: ./firmware/build/test_suite_main.elf
HEX file: ./firmware/build/test_suite_main.hex
Size: ...
[SUCCESS] Build complete!
```

### 2. Run Simulation

```bash
# Run with iverilog (default)
make -f Makefile.fw simulate

# Or use simulation script
./simulate.sh iverilog test_suite_main
```

**Output:**
```
[SIM] SparkMCU RTL Test: test_suite_main
[SIM] Simulator: iverilog
[OK] Hex file found: ./firmware/build/test_suite_main.hex
[COMPILE] Compiling design
[OK] iVerilog compilation successful
[RUN] Running simulation
[TB] System initialized, running tests...
[TB] Time: 100

[TEST] GPIO Port B R/W ... PASS
[TEST] GPIO Port C R/W ... PASS
[TEST] GPIO Port D R/W ... PASS
[TEST] Timer0 Basic Operation ... PASS
...

[TB] ===== TEST RESULTS =====
[TB] PASS: 14
[TB] FAIL: 0
[TB] TOTAL: 14
[TB] TEST: PASSED
```

### 3. Complete Verification Flow

```bash
# Clean, build, and simulate in one command
make -f Makefile.fw verify
```

## Test Framework API

The test framework (`firmware/include/test_framework.h`) provides simple utilities:

### Initialization

```c
void test_init(void);          // Initialize test framework
void test_report(void);        // Print final test report
```

### Test Cases

```c
void test_start(const char *test_name);           // Start a test
void test_assert(uint8_t condition, const char *msg);  // Check condition
void test_end(void);           // End current test (auto reports PASS/FAIL)
```

### UART Functions

```c
void uart_init(void);          // Initialize UART
void uart_puts(const char *str);       // Transmit string
void uart_tx_byte(uint8_t data);       // Transmit single byte
void uart_put_hex(uint8_t val);        // Print hex byte (e.g., "A5")
void uart_put_hex16(uint16_t val);     // Print hex word (e.g., "1234")
```

### GPIO Utilities

```c
void gpio_init_outputs(void);
void gpio_write_byte(uint8_t port, uint8_t value);  // 0=B, 1=C, 2=D
uint8_t gpio_read_byte(uint8_t port);
```

### Timer Utilities

```c
void timer0_init(uint8_t prescaler);
uint8_t timer0_read(void);
void timer0_write(uint8_t value);
uint8_t timer0_overflow_flag(void);
void timer0_clear_overflow_flag(void);
void delay_ms(uint16_t ms);
```

## Writing Custom Test Cases

### Example 1: Simple GPIO Test

```c
void test_gpio_custom(void) {
    test_start("Custom GPIO Test");
    
    gpio_init_outputs();
    
    // Test: Write 0x42 to Port B
    gpio_write_byte(0, 0x42);
    delay_ms(1);
    uint8_t value = gpio_read_byte(0);
    
    // Assert the value matches
    test_assert(value == 0x42, "Port B value mismatch");
    
    test_end();
}
```

### Example 2: Timer Interrupt Test

```c
volatile uint8_t timer_interrupt_count = 0;

ISR(TIMER0_OVF_vect) {
    timer_interrupt_count++;
}

void test_timer_interrupt(void) {
    test_start("Timer Interrupt");
    
    timer_interrupt_count = 0;
    
    // Configure and enable timer interrupt
    TCCR0B = 0x01;       // Prescaler 1:1
    TIMSK0 = (1 << TOIE0);  // Enable overflow interrupt
    sei();               // Global interrupt enable
    
    // Wait for overflow
    timer0_write(0xF0);
    delay_ms(5);
    
    cli();               // Disable interrupts
    test_assert(timer_interrupt_count > 0, "Timer interrupt not fired");
    
    test_end();
}
```

### Adding Tests to Test Suite

Edit `firmware/src/test_suite_main.c` and add:

```c
int main(void) {
    test_init();
    
    // ... existing tests ...
    
    test_gpio_custom();        // Add your custom test
    test_timer_interrupt();    // Add timer test
    
    test_report();
    
    while (1);
}
```

## UART Output Format

### Test Output

Each test produces output in this format:

```
[TEST] Test Description ... PASS
[TEST] Test Description ... FAIL
```

### Final Report

```
================================
Test Results:
================================
PASS: 14
FAIL: 0
TOTAL: 14
STATUS: ALL TESTS PASSED
================================
```

### Failure Details

When a test assertion fails:

```
[TEST] GPIO Port B R/W ... FAIL: Pattern 0x55 mismatch
```

## HDL Testbench Integration

The testbench (`testbench/spark_mcu_test_tb.v`) provides:

1. **Clock and Reset**: 16 MHz clock generation and active-low reset
2. **Hex File Loading**: Loads firmware via `$readmemh`
3. **UART Monitoring**: Decodes UART frames at 9600 baud
4. **Test Parsing**: Recognizes PASS/FAIL keywords in output
5. **Result Collection**: Counts passing/failing tests
6. **Timeout Protection**: Prevents infinite simulation

### UART Monitor Implementation

The testbench includes a synchronous UART receiver that:

```verilog
// Monitors uart_txd (DUT's UART transmitter)
// Decodes frames: START + 8 DATA BITS + STOP
// Samples at UART_PERIOD timing
// Prints characters to simulation output
// Recognizes PASS/FAIL strings
```

### Customizing Testbench Parameters

In `testbench/spark_mcu_test_tb.v`:

```verilog
parameter CLK_PERIOD = 62.5;        // 16 MHz (ns)
parameter UART_BAUD  = 9600;        // Baud rate
parameter HEX_FILE   = "firmware/build/test.hex";  // Hex file
parameter SIM_TIME   = 100000000;   // Max simulation (ns)
```

## Flash ROM Module

The new `spark_flash_rom.v` module provides:

```verilog
module spark_flash_rom #(
    parameter DEPTH   = 16384,      // 16K x 16-bit words
    parameter AW      = 14,         // Address width
    parameter HEX_FILE = ""         // Path to .hex file
);
```

### Features

- **$readmemh Support**: Loads Intel HEX files at initialization
- **Synchronous Read**: One-cycle latency
- **Debug Monitor Port**: Read-only access for waveform viewing
- **Programming Port**: For bootloader or runtime updates

### Usage

```verilog
spark_flash_rom #(
    .DEPTH(16384),
    .AW(14),
    .HEX_FILE("firmware/build/test.hex")
) u_flash (
    .clk(clk),
    .rst_n(rst_n),
    .fetch_addr(addr),
    .fetch_data(data),
    .fetch_en(rd_en)
);
```

## Supported Test Examples

### Current Test Suite (`test_suite_main.c`)

1. **GPIO Port B**: Read/write patterns (0x55, 0xAA, 0xFF, 0x00)
2. **GPIO Port C**: 6-bit patterns (0x15, 0x2A)
3. **GPIO Port D**: Full-width patterns
4. **Timer0 Basic**: Counter increment verification
5. **Timer0 Overflow**: Overflow flag detection
6. **UART Loopback**: Transmission verification
7. **ALU Addition**: 0x12 + 0x34, overflow detection
8. **ALU Subtraction**: 0x50 - 0x30, underflow detection
9. **ALU AND/OR/XOR**: Bitwise operation verification
10. **SPI Communication**: Master mode initialization
11. **External Interrupt INT0**: Configuration verification
12. **Memory R/W**: SRAM read/write patterns

## Build System

### Using Makefile

```bash
# Display help
make -f Makefile.fw help

# Build firmware
make -f Makefile.fw build-fw TEST_NAME=test_suite_main

# Run simulation (requires build-fw first)
make -f Makefile.fw simulate

# Complete flow: clean, build, simulate
make -f Makefile.fw verify

# Clean build artifacts
make -f Makefile.fw clean
```

### Using Shell Scripts

```bash
# Build firmware
./build_firmware.sh test_suite_main

# Simulate with iverilog
./simulate.sh iverilog test_suite_main

# Simulate with other simulators (if supported)
./simulate.sh vivado test_suite_main
./simulate.sh modelsim test_suite_main
```

## Debugging

### Generate Waveform

Uncomment in testbench to generate VCD file:

```verilog
initial begin
    $dumpfile("spark_mcu_test.vcd");
    $dumpvars(0, spark_mcu_test_tb);
end
```

View with:
```bash
gtkwave firmware/build/spark_mcu_test.vcd
```

### Monitor Signals

Add debug prints in testbench:

```verilog
$display("Time: %t, PC: %h, Instr: %h", $time, debug_pc, dut.current_instr);
```

### Check Compilation

```bash
# Verbose output
make -f Makefile.fw build-fw VERBOSE=1

# Check object files
ls -lh firmware/build/
```

## Requirements

### Software
- `avr-gcc` (AVR toolchain)
- `avr-objcopy`
- `avr-size`
- `iverilog` (or other Verilog simulator)
- `vvp` (Icarus runtime)

### Installation (Ubuntu/Debian)

```bash
sudo apt-get install gcc-avr binutils-avr avr-libc
sudo apt-get install iverilog
```

### Installation (macOS)

```bash
brew install avr-gcc
brew install icarus-verilog
```

## Troubleshooting

### Error: "avr-gcc not found"

Install AVR toolchain:
```bash
# Ubuntu/Debian
sudo apt-get install gcc-avr

# macOS
brew install avr-gcc

# Or download from https://www.microchip.com/
```

### Error: "Hex file not found"

Build firmware first:
```bash
make -f Makefile.fw build-fw
```

### Error: "iverilog not found"

Install Icarus Verilog:
```bash
# Ubuntu/Debian
sudo apt-get install iverilog

# macOS
brew install icarus-verilog
```

### Simulation hangs or timeout

Increase simulation time in testbench or Makefile:
```makefile
SIM_TIME = 200000000  # 200ms instead of 100ms
```

### UART output not captured

Check testbench UART baud rate matches firmware:
```c
#define UART_BAUD 9600  // Firmware side
```

```verilog
parameter UART_BAUD = 9600;  // Testbench side
```

## Extending the Verification

### Add New Peripheral Tests

1. Create test in `firmware/src/test_suite_main.c`
2. Use test framework API
3. Output results via UART
4. Rebuild and simulate

### Integrate with CI/CD

Example GitHub Actions workflow:

```yaml
name: SparkMCU Tests
on: [push, pull_request]
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install toolchain
        run: sudo apt-get install gcc-avr binutils-avr iverilog
      - name: Build firmware
        run: make -f Makefile.fw build-fw
      - name: Run simulation
        run: make -f Makefile.fw simulate
```

### Add Register Test Macros

Enhanced assertion macros for register testing:

```c
#define TEST_REG_WRITE(reg, val, name) \
    do { \
        (reg) = (val); \
        delay_ms(1); \
        test_assert((reg) == (val), name " mismatch"); \
    } while(0)
```

## References

- AVR Instruction Set: https://www.microchip.com/
- ATmega328P Datasheet: https://ww1.microchip.com/
- iVerilog Documentation: http://www.icarus.com/eda/verilog/
- Intel HEX Format: https://en.wikipedia.org/wiki/Intel_HEX

---

**Last Updated:** March 2026
**SparkMCU Version:** 1.0
