# SparkMCU Verification: Quick Start Guide

## 5-Minute Quick Start

### Prerequisites
```bash
# Check if tools are installed
avr-gcc --version
iverilog -version

# If not, install:
# Ubuntu/Debian:
sudo apt-get install gcc-avr binutils-avr avr-libc iverilog

# macOS:
brew install avr-gcc icarus-verilog
```

### Run Complete Verification
```bash
# From SparkMCU directory
cd /home/shahrear/OpenLane/designs/SparkMCU

# One command to build firmware and run tests
make -f Makefile.fw verify
```

**Expected output:**
```
[BUILD] SparkMCU Firmware (test_suite_main)
[TEST] GPIO Port B R/W ... PASS
[TEST] Timer0 Basic ... PASS
...
[TB] TEST: PASSED
```

### That's it!

If you see `[TB] TEST: PASSED`, everything works.

---

## Step-by-Step Workflow

### Step 1: Build Firmware Only
```bash
make -f Makefile.fw build-fw
```

Output files:
- `firmware/build/test_suite_main.elf` - Compiled binary
- `firmware/build/test_suite_main.hex` - Hex file for simulation

### Step 2: Simulate Only
```bash
make -f Makefile.fw simulate
```

Requires `.hex` file from Step 1.

### Step 3: View Full Report
```bash
make -f Makefile.fw clean      # Start fresh
make -f Makefile.fw verify     # Complete flow

# Then check output file
cat firmware/build/spark_mcu_test.lxt  # Or open in gtkwave
```

---

## Common Commands

| Task | Command |
|------|---------|
| Build specific test | `make -f Makefile.fw build-fw TEST_NAME=led_toggle_main` |
| Simulate | `make -f Makefile.fw simulate` |
| Clean | `make -f Makefile.fw clean` |
| Help | `make -f Makefile.fw help` |
| Everything | `make -f Makefile.fw verify` |

---

## Add Your Own Test

### 1. Add test function to `firmware/src/test_suite_main.c`

```c
void test_my_feature(void) {
    test_start("My Feature Test");
    
    // Your test code here
    uint8_t result = some_operation();
    
    test_assert(result == expected, "Result mismatch");
    
    test_end();
}
```

### 2. Add to main()

```c
int main(void) {
    test_init();
    
    // ... existing tests ...
    
    test_my_feature();  // Add your test
    
    test_report();
    while (1);
    return 0;
}
```

### 3. Rebuild and Test

```bash
make -f Makefile.fw verify
```

---

## Troubleshooting

### Build fails: "avr-gcc not found"
```bash
# Install AVR tools
# Ubuntu: sudo apt-get install gcc-avr
# macOS: brew install avr-gcc
```

### Simulation hangs
```bash
# Increase timeout in Makefile.fw
# Change: SIM_TIME = 100000000  (to 200000000)
# Then: make -f Makefile.fw clean simulate
```

### No UART output in simulation
```bash
# Check baud rates match:
# C code: #define UART_BAUD 9600
# Verilog: parameter UART_BAUD = 9600;
```

### Test fails unexpectedly
1. Check firmware builds: `make -f Makefile.fw build-fw`
2. Check hex file exists: `ls -lh firmware/build/*.hex`
3. Verify RTL files: `ls rtl/*/*.v`
4. Run clean flow: `make -f Makefile.fw clean verify`

---

## File Locations

| File | Purpose |
|------|---------|
| `firmware/src/test_suite_main.c` | Main test suite |
| `firmware/include/test_framework.h` | Test utilities |
| `firmware/build/test_suite_main.hex` | Generated hex file |
| `rtl/memory/spark_flash_rom.v` | Flash ROM module |
| `testbench/spark_mcu_test_tb.v` | Testbench |
| `Makefile.fw` | Build automation |

---

## Understanding UART Output

### During Simulation
```
[ TEST] GPIO Port B R/W ... PASS
 ↑     ↑                      ↑
 |     |                      └─ Result
 |     └─ Test name
 └─ Timestamp
```

### Final Report
```
========================
Test Results:
PASS: 14         ← Passed tests
FAIL: 0          ← Failed tests
TOTAL: 14        ← Total tests
STATUS: ALL TESTS PASSED
========================
```

---

## Changing Test Parameters

### Clock Frequency
Edit `firmware/include/test_framework.h`:
```c
#define F_CPU 16000000UL  // Change this
```

### UART Baud Rate
Firmware: `firmware/include/test_framework.h`
```c
#define UART_BAUD 9600  // Change this
```

Testbench: `testbench/spark_mcu_test_tb.v`
```verilog
parameter UART_BAUD = 9600;  // Must match
```

### Simulation Time
Makefile: `Makefile.fw`
```makefile
SIM_TIME = 100000000  # in ns (currently 100ms)
```

---

## Common Test Patterns

### GPIO Test
```c
void test_gpio_example(void) {
    test_start("GPIO Example");
    
    gpio_init_outputs();
    gpio_write_byte(0, 0x42);      // Write to Port B
    delay_ms(1);
    uint8_t val = gpio_read_byte(0);
    
    test_assert(val == 0x42, "GPIO failed");
    test_end();
}
```

### Timer Test
```c
void test_timer_example(void) {
    test_start("Timer Example");
    
    timer0_init(0x01);  // Prescaler 1:1
    timer0_write(0x00);
    delay_ms(5);
    
    uint8_t count = timer0_read();
    test_assert(count > 0, "Timer not counting");
    test_end();
}
```

### Memory Test
```c
void test_memory_example(void) {
    test_start("Memory Example");
    
    volatile uint8_t *addr = (uint8_t *)0x0200;
    
    *addr = 0xAA;
    delay_ms(1);
    
    test_assert(*addr == 0xAA, "Memory RW failed");
    test_end();
}
```

---

## Getting Detailed Output

### Enable VCD Waveform
In `testbench/spark_mcu_test_tb.v`, uncomment:
```verilog
initial begin
    $dumpfile("spark_mcu_test.vcd");
    $dumpvars(0, spark_mcu_test_tb);
end
```

Then view with:
```bash
gtkwave firmware/build/spark_mcu_test.vcd
```

### Print Debug Info
Add to test code:
```c
uart_puts("Debug: ");
uart_put_hex(register_value);
uart_puts("\r\n");
```

---

## Next Steps

1. ✅ Run `make -f Makefile.fw verify` - Verify everything works
2. 📝 Read [VERIFICATION_FLOW.md](VERIFICATION_FLOW.md) - Full detailed guide
3. 🏗️ Read [ARCHITECTURE.md](ARCHITECTURE.md) - How it works internally
4. ➕ Add custom tests - Extend test suite for your IP blocks
5. 🔧 Integrate with CI/CD - Automate verification in your workflow

---

**Questions?** Check the full documentation:
- Complete guide: [VERIFICATION_FLOW.md](VERIFICATION_FLOW.md)
- Architecture details: [ARCHITECTURE.md](ARCHITECTURE.md)
- Firmware details: [firmware/README.md](firmware/README.md)

---

**Version**: 1.0 | **Updated**: March 2026 | **SparkMCU v1.0**
