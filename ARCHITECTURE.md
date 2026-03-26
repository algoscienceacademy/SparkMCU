# SparkMCU Firmware-Driven Verification: Architecture & Implementation Guide

## System Architecture Overview

### High-Level Verification Flow

```
┌──────────────────────────────────────────────────────────────────┐
│  Stage 1: Firmware Compilation                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  C Code (test_suite_main.c)                                      │
│      │                                                            │
│      └─→ avr-gcc ──→ ELF Binary ──→ avr-objcopy ──→ HEX File   │
│                                                                   │
│  Output: firmware/build/test_suite_main.hex                      │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Stage 2: HDL Simulation                                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  RTL Files (Verilog)                                             │
│      │                                                            │
│      ├─→ spark_mcu_top.v (top-level SoC)                        │
│      ├─→ spark_cpu.v (CPU core)                                 │
│      ├─→ spark_flash_rom.v (program memory with $readmemh)      │
│      ├─→ spark_*_*.v (peripherals)                              │
│      │                                                            │
│      └─→ iverilog ──→ VVP Simulation Binary                     │
│                                                                   │
│  Testbench (spark_mcu_test_tb.v)                                │
│      │                                                            │
│      ├─→ Loads HEX file into flash ROM                          │
│      ├─→ Instantiates SparkMCU RTL                              │
│      ├─→ Generates clock & reset                                │
│      ├─→ Monitors UART output                                   │
│      └─→ Collects test results                                  │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Stage 3: Test Execution & Result Capture                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  MCU Simulation                                                  │
│      │                                                            │
│      ├─→ CPU fetches instructions from flash ROM                │
│      ├─→ CPU executes firmware code                             │
│      ├─→ Firmware writes test results to UART register          │
│      │                                                            │
│      └─→ UART TX sends serial data                              │
│                  │                                               │
│                  └─→ Testbench UART Monitor                     │
│                      ├─→ Detects START bit (falling edge)       │
│                      ├─→ Samples 8 data bits                    │
│                      ├─→ Detects STOP bit                       │
│                      ├─→ Decodes ASCII character                │
│                      └─→ Collects PASS/FAIL keywords            │
│                                                                   │
│  Test Results:                                                   │
│      PASS_COUNT = N                                              │
│      FAIL_COUNT = M                                              │
│      STATUS = (M == 0) ? PASS : FAIL                            │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Flash ROM Module (`spark_flash_rom.v`)

The Flash ROM is the bridge between the HEX file (compiled firmware) and the RTL simulation:

```verilog
module spark_flash_rom #(
    parameter DEPTH   = 16384,      // 16K x 16-bit words (32KB)
    parameter AW      = 14,         // Address width
    parameter HEX_FILE = ""         // Path to Intel HEX file
)(
    input  wire clk,
    input  wire rst_n,
    
    // CPU fetch interface
    input  wire [AW-1:0] fetch_addr,
    output wire [15:0]   fetch_data,
    input  wire          fetch_en,
    
    // Debug/Monitor interface
    output wire [15:0]   monitor_data,
    input  wire [AW-1:0] monitor_addr,
    input  wire          monitor_en,
    
    // Programming interface (optional)
    input  wire [AW-1:0] prog_addr,
    input  wire [15:0]   prog_data,
    input  wire          prog_we
);
```

**Key features:**

1. **Initialization with $readmemh**:
   ```verilog
   initial begin
       if (HEX_FILE != "")
           $readmemh(HEX_FILE, mem);
   end
   ```
   
2. **Synchronous read**: One-cycle latency for instruction fetch
3. **No write conflicts**: Read and write ports independent
4. **Flexible size**: Parametrized memory depth and address width

### 2. Enhanced Testbench (`spark_mcu_test_tb.v`)

The testbench orchestrates the complete verification:

#### Initialization Phase
```verilog
initial begin
    // 1. Set all inputs to idle state
    rst_n = 0;
    uart_rxd = 1;  // UART idle
    
    // 2. Release reset after 100ns
    #100 rst_n = 1;
    
    // 3. Firmware executes for up to SIM_TIME
    // 4. Parse UART output for PASS/FAIL
    // 5. Generate final report
end
```

#### UART Monitor (Synchronous Receiver)

The testbench includes a real UART decoder that:

1. **Detects start bit**: Falling edge on uart_txd
2. **Samples data bits**: At baud rate timing (104.2 µs per bit at 9600 baud)
3. **Validates frame**: Expects valid stop bit
4. **Decodes to ASCII**: Converts 8-bit data to character
5. **Processes output**: Looks for PASS/FAIL keywords

```verilog
// UART frame format (9600 baud, 8N1):
// ─────────────────────────────────────
//  1 START | 8 DATA BITS | 1 STOP |
//  0      |  b0-b7      | 1      |
// ─────────────────────────────────────
//  ~104µs | ~832µs       | ~104µs |
```

#### Result Processing

```verilog
task parse_test_output(string line);
    if ($strpos(line, "PASS") != -1)
        test_pass_count += 1;
    else if ($strpos(line, "FAIL") != -1)
        test_fail_count += 1;
endtask
```

### 3. Test Framework (`test_framework.h`)

The C framework provides:

#### Architecture
```
┌─────────────────────────────────────────┐
│  Test Framework (C Library)             │
├─────────────────────────────────────────┤
│                                         │
│  UART Layer:                            │
│    - uart_init(): Set baud rate         │
│    - uart_tx_byte(): Send byte          │
│    - uart_puts(): Send string           │
│    - uart_put_hex(): Format output      │
│                                         │
│  Test API:                              │
│    - test_init(): Initialize framework  │
│    - test_start(name): Begin test       │
│    - test_assert(cond, msg): Check      │
│    - test_end(): Report result          │
│    - test_report(): Final summary       │
│                                         │
│  Peripheral Utilities:                  │
│    - GPIO read/write                    │
│    - Timer control                      │
│    - Delay functions                    │
│    - Interrupt setup                    │
│                                         │
└─────────────────────────────────────────┘
```

#### Test Flow in Firmware
```c
test_init();           // Initialize, print header

// For each test:
test_start("Test Name");           // Print "[TEST] Test Name ..."
test_assert(cond1, "msg1");        // Check condition
test_assert(cond2, "msg2");        // Check another condition
test_end();                        // Print " PASS" or " FAIL"

// After all tests:
test_report();         // Print summary
```

### 4. Build System

#### Compilation Flow
```
C Source (.c)
    │
    ├─→ [avr-gcc] (Preprocessing + Compilation)
    │
    ├─→ Assembly (.s)
    │
    ├─→ [Assembler]
    │
    ├─→ Object Code (.o)
    │
    ├─→ [Linker] (linking, symbol resolution)
    │
    ├─→ ELF Binary (.elf)
    │
    ├─→ [avr-objcopy] (Format conversion)
    │
    └─→ Intel HEX (.hex)
```

#### Build Flags

| Flag | Purpose |
|------|---------|
| `-mmcu=atmega328p` | Target microcontroller |
| `-DF_CPU=16000000UL` | CPU frequency (used by delay macros) |
| `-Os` | Size optimization |
| `-Wall -Wextra` | Enable warnings |
| `-std=gnu99` | C language standard |

#### Hex File Format

Intel HEX is a text-based format:
```
:10000000E0E3F0E0E2EFF0E01E92F1E0C0EAD0FA4
:10001000C0E8D1E0C8E7D0E0DEBCCECF1CD0C000
...
:00000001FF
```

Each line:
```
:LLAAAATTDD...DD[CC]

LL    = Byte count (data bytes)
AAAA  = Address (16-bit)
TT    = Record type (00=data, 01=EOF, etc.)
DD    = Data bytes
CC    = Checksum (2's complement)
```

$readmemh parses this format and fills the memory array.

## Integration with Existing MCU

The SparkMCU top-level (`spark_mcu_top.v`) currently uses `spark_pmem` for program memory. To use the flash ROM approach:

### Option 1: Replace Program Memory (Recommended)

Modify `spark_mcu_top.v`:

```verilog
// OLD:
// spark_pmem u_pmem (
//     .clk(clk), .rst_n(rst_n),
//     .addr(pm_addr), .rdata(pm_data), .rd_en(pm_rd),
//     .prog_addr(prog_addr), .prog_data(prog_data), .prog_wr(prog_wr)
// );

// NEW:
spark_flash_rom #(
    .DEPTH(16384),
    .AW(14),
    .HEX_FILE("")  // Overridden in testbench
) u_flash_rom (
    .clk(clk),
    .rst_n(rst_n),
    .fetch_addr(pm_addr),
    .fetch_data(pm_data),
    .fetch_en(pm_rd),
    .prog_addr(prog_addr),
    .prog_data(prog_data),
    .prog_we(prog_wr),
    .monitor_addr('0),
    .monitor_en(1'b0),
    .monitor_data()
);
```

### Option 2: Keep Original, Add Flash in Testbench

Keep the original `spark_pmem`, and instantiate `spark_flash_rom` externally in the testbench.

**Pros**: Non-intrusive, reversible
**Cons**: More complex testbench

## Firmware Execution Example

### Command
```bash
make -f Makefile.fw verify TEST_NAME=test_suite_main
```

### Step 1: Compile
```bash
avr-gcc -mmcu=atmega328p -DF_CPU=16000000UL -Os -I... \
        -c firmware/src/test_suite_main.c -o firmware/build/test_suite_main.o
avr-gcc ... firmware/build/test_suite_main.o -o firmware/build/test_suite_main.elf
avr-objcopy -O ihex firmware/build/test_suite_main.elf \
           firmware/build/test_suite_main.hex
```

### Step 2: HEX File Content
```
:020000040000FA
:10000000E0E3F0E0E2EFF0E01E92F1E0C0EAD0FA4  <- Test initialization
:100010003C910500089401E0F0E010E0D0944CE013  <- Test case 1
:100020007894919093FF9D93B99F7FB9DD99F993FE  <- Test case 2
...
:00000001FF  <- End of file
```

### Step 3: Simulation Startup
```
Clock generation starts: 16 MHz
Reset released: MCU initializes
CPU fetches from address 0x0000: Instruction from HEX file loaded into flash ROM
```

### Step 4: Firmware Execution
```
1. MCU boot vector calls main()
2. test_init() initializes UART
3. UART outputs: "================================"
4. test_gpio_port_b() executes
5. GPIO register writes verified
6. UART outputs: "PASS"
7. ... (repeat for all tests)
8. test_report() outputs final count
9. Firmware loops forever
10. Testbench detects "PASSED" and exits
```

### Step 5: Complete Output
```
[TB] System initialized, running tests...

[TEST] GPIO Port B R/W ... PASS
[TEST] GPIO Port C R/W ... PASS
[TEST] GPIO Port D R/W ... PASS
[TEST] Timer0 Basic Operation ... PASS
[TEST] Timer0 Overflow ... PASS
[TEST] UART Loopback ... PASS
[TEST] ALU Addition ... PASS
[TEST] ALU Subtraction ... PASS
[TEST] ALU Bitwise AND ... PASS
[TEST] ALU Bitwise OR ... PASS
[TEST] ALU Bitwise XOR ... PASS
[TEST] SPI Basic Communication ... PASS
[TEST] External Interrupt INT0 ... PASS
[TEST] Memory Read/Write ... PASS

================================
Test Results:
================================
PASS: 14
FAIL: 0
TOTAL: 14
STATUS: ALL TESTS PASSED
================================

[TB] ===== TEST RESULTS =====
[TB] PASS: 14
[TB] FAIL: 0
[TB] TOTAL: 14
[TB] TEST: PASSED
```

## Timing & Baud Rate Calculation

### UART Timing at 9600 Baud

| Component | Duration |
|-----------|----------|
| 1 bit | 104.166 µs |
| START bit | 0 - 104.166 µs |
| Data bits (8) | ~832 µs total |
| STOP bit | 104.166 µs |
| **Total frame** | **~1041.6 µs** |

### Clock Cycles at 16 MHz

| Component | Cycles |
|-----------|--------|
| 1 ns | 0.016 clocks |
| 1 bit (104.166 µs) | ~1667 clocks |
| Full frame (~1.04 ms) | ~16,667 clocks |

### Example: Transmitting 'P' (0x50)
```
Bit timing (1 per 1667 clocks):

Clock:  0     1667   3334   5001   6668   8335  10002  11669  13336  15003
        ↓      ↓      ↓      ↓      ↓      ↓      ↓      ↓      ↓      ↓
Signal: ─────┐                                                        ┌─────
        START│ 0  1  0  1  0  1  0  0   STOP │
             └─────────────────────────────────┘
             
Frame: [0][1010100][1]  <- 0x50 = 'P'
```

## Performance Considerations

### Simulation Speed
- **Clock frequency**: 16 MHz
- **Testbench timestep**: 1 ns (62.5 ns per clock cycle)
- **Typical simulation speed**: 100K-1M clocks per second (varies by CPU)

### Test Coverage
Current implementation tests:
- ✅ GPIO output (all ports)
- ✅ Timer functionality
- ✅ UART transmission
- ✅ ALU operations (ADD, SUB, AND, OR, XOR)
- ✅ SPI configuration
- ✅ Interrupt setup
- ✅ Memory access

### Extensibility

Easy to add:
- ⏳ More ALU operations (shifts, rotations)
- ⏳ UART RX testing
- ⏳ SPI full master/slave
- ⏳ All timer modes (PWM, CTC, etc.)
- ⏳ ADC measurements
- ⏳ EEPROM access
- ⏳ Interrupt handling verification
- ⏳ Stack pointer validation

## Debugging Techniques

### 1. Print Debug Information

Add to testbench:
```verilog
always @(posedge clk) begin
    if (pc_changed)
        $display("[PC] %d -> %h", $time, debug_pc);
end
```

### 2. Monitor Specific Signals

```verilog
always @(posedge clk) begin
    $write("[%t] UART TXD=%b, GPIO_B=%h, TIMER=%h\n", 
           $time, uart_txd, portb_out, tmr0_counter);
end
```

### 3. Assert Properties

```verilog
always @(posedge clk) begin
    assert(dut.cpu_state < 16) 
        else $error("Invalid CPU state: %h", dut.cpu_state);
end
```

### 4. Conditional Breakpoints

```verilog
always @(posedge clk) begin
    if (debug_pc == 16'h0100) begin
        $display("[BREAKPOINT] Reached 0x0100");
        $finish;
    end
end
```

## References & Further Reading

- **AVR Instruction Set Manual**: https://ww1.microchip.com/
- **Intel HEX Format**: https://en.wikipedia.org/wiki/Intel_HEX
- **Verilog LRM 1364-2005**: IEEE standard
- **iVerilog Documentation**: http://www.icarus.com/eda/verilog/

---

**Document Version**: 1.0  
**Last Updated**: March 2026  
**SparkMCU Version**: 1.0
