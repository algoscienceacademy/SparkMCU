# SparkMCU Firmware-Driven Verification: START HERE 📖

Welcome! You now have a **complete firmware-driven RTL verification system** for SparkMCU.

---

## 🚀 Quick Start (2 minutes)

```bash
cd /home/shahrear/OpenLane/designs/SparkMCU

# Run complete verification
make -f Makefile.fw verify

# Expected output:
# [TB] ===== TEST RESULTS =====
# [TB] PASS: 14
# [TB] FAIL: 0
# [TB] TOTAL: 14
# [TB] TEST: PASSED
```

If you see `[TB] TEST: PASSED`, everything works! 🎉

---

## 📚 Documentation Organization

Choose your starting point:

### 👤 For First-Time Users
**[QUICKSTART.md](QUICKSTART.md)** ← Start here (5 minutes)
- Essential commands
- Common tasks
- Quick solutions

### 🔧 For Installation/Setup
**[SETUP.md](SETUP.md)** (30 minutes)
- Tool installation (Ubuntu, macOS, Windows, Docker)
- Verification checklist
- Troubleshooting

### 📖 For Complete Guide
**[VERIFICATION_FLOW.md](VERIFICATION_FLOW.md)** (1-2 hours)
- Full system explanation
- Test framework usage
- All features
- Debugging guide

### 🏗️ For Architecture Details
**[ARCHITECTURE.md](ARCHITECTURE.md)** (1-2 hours)
- Component design
- System integration
- Timing analysis
- Implementation details

### 📋 For File Reference
**[FILE_REFERENCE.md](FILE_REFERENCE.md)** (30 minutes)
- Every file's purpose
- Dependencies
- How things connect

### 📊 For Executive Summary
**[README-VERIFICATION.md](README-VERIFICATION.md)** (10 minutes)
- What was delivered
- Key features
- Statistics

### ✅ For Implementation Status
**[DELIVERY_CHECKLIST.md](DELIVERY_CHECKLIST.md)** (5 minutes)
- Complete feature list
- Files created
- Ready-to-use status

---

## 📦 What You Have

### Core Components

✅ **Flash ROM Module** (`rtl/memory/spark_flash_rom.v`)
- Loads .hex files via $readmemh
- Used by testbench simulation

✅ **Enhanced Testbench** (`testbench/spark_mcu_test_tb.v`)
- UART real-time decoder
- PASS/FAIL capture
- Automatic result reporting

✅ **Test Framework Library** (`firmware/include/test_framework.h`)
- Ready-to-use test API
- 250 lines of reusable code

✅ **Comprehensive Test Suite** (`firmware/src/test_suite_main.c`)
- 14 test cases
- GPIO, Timer, UART, ALU, SPI, Interrupts, Memory
- 550 lines of test code

✅ **Build Automation** (Makefile.fw, scripts)
- One-command build + simulate
- Multi-simulator support
- Error handling

✅ **Extensive Documentation** (6 guides)
- 4,500+ lines of explanation
- Examples and tutorials
- Troubleshooting guide

---

## 🎯 What You Can Do Now

### 1. Run Complete Verification (2 minutes)
```bash
make -f Makefile.fw verify
```

### 2. Build Firmware Only (1 minute)
```bash
make -f Makefile.fw build-fw
```

### 3. Run Simulation Only (30 seconds)
```bash
make -f Makefile.fw simulate
```

### 4. Clean Everything (5 seconds)
```bash
make -f Makefile.fw clean
```

### 5. Add Custom Tests (10 minutes)
Edit `firmware/src/test_suite_main.c` and rebuild

### 6. View Test Output (Real-time)
Simulation outputs UART messages as tests run

---

## 🏗️ System Architecture

```
Firmware (C)                  RTL (Verilog)
──────────────               ─────────────

C source → avr-gcc          RTL files
   ↓
ELF binary → avr-objcopy    ├─ CPU core
   ↓                        ├─ Peripherals
HEX file → $readmemh ──→ Flash ROM
                            ├─ Testbench
                            └─ UART Monitor
                                 ↓
                        Simulation Output
                                 ↓
                        PASS/FAIL Results
```

---

## 📊 Included Tests

✅ GPIO Port B (read/write)  
✅ GPIO Port C (6-bit)  
✅ GPIO Port D (read/write)  
✅ Timer0 counter  
✅ Timer0 overflow  
✅ UART transmission  
✅ ALU: ADD, SUB, AND, OR, XOR  
✅ SPI master mode  
✅ External interrupt INT0  
✅ Memory read/write  

**Total: 14 test cases** covering **8 peripherals**

---

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| Microcontroller | AVR (ATmega328P ISA compatible) |
| Hardware | Verilog RTL |
| Firmware | C (avr-gcc) |
| Simulator | iVerilog + VVP |
| Build | GNU Make |
| Testing | Custom UART protocol |

---

## 📂 Key Files at a Glance

### New RTL
- `rtl/memory/spark_flash_rom.v` - Program memory loader

### New Testbench
- `testbench/spark_mcu_test_tb.v` - UART monitor + result capture

### New Firmware
- `firmware/include/test_framework.h` - Test library
- `firmware/src/test_suite_main.c` - 14 test cases

### Build System
- `Makefile.fw` - Main build automation
- `build_firmware.sh` - Build script
- `simulate.sh` - Simulation script

### Documentation
- `QUICKSTART.md` - 5-minute start
- `SETUP.md` - Installation guide
- `VERIFICATION_FLOW.md` - Complete guide
- `ARCHITECTURE.md` - Design details
- `FILE_REFERENCE.md` - File reference
- `README-VERIFICATION.md` - Summary
- `DELIVERY_CHECKLIST.md` - Checklist

---

## ⚡ Common Commands

```bash
# Run everything
make -f Makefile.fw verify

# Build firmware
./build_firmware.sh test_suite_main

# Run simulation
./simulate.sh iverilog test_suite_main

# Get help
make -f Makefile.fw help

# Clean artifacts
make -f Makefile.fw clean

# Build + show help
make -f Makefile.fw help
```

---

## 🎓 Learning Path

### Level 1 - Quick Start (5 min)
→ Read [QUICKSTART.md](QUICKSTART.md)
→ Run `make -f Makefile.fw verify`

### Level 2 - Basic Usage (30 min)
→ Read [VERIFICATION_FLOW.md](VERIFICATION_FLOW.md) - "Quick Start" section
→ Try different test targets

### Level 3 - Complete Understanding (1-2 hours)
→ Read full [VERIFICATION_FLOW.md](VERIFICATION_FLOW.md)
→ Read [ARCHITECTURE.md](ARCHITECTURE.md)

### Level 4 - Customization (1-2 hours)
→ Read [test_framework.h](firmware/include/test_framework.h)
→ Study [test_suite_main.c](firmware/src/test_suite_main.c)
→ Add custom tests

### Level 5 - Advanced (2-3 hours)
→ Study [spark_flash_rom.v](rtl/memory/spark_flash_rom.v)
→ Study [spark_mcu_test_tb.v](testbench/spark_mcu_test_tb.v)
→ Extend simulator support

---

## ❓ Frequently Asked Questions

**Q: How do I run the tests?**
A: `make -f Makefile.fw verify` - that's it!

**Q: Where are the results?**
A: Printed to console during simulation. Also check `firmware/build/` for output files.

**Q: How do I add new tests?**
A: Edit `firmware/src/test_suite_main.c`, add test function, rebuild.

**Q: What if tools aren't installed?**
A: See [SETUP.md](SETUP.md) for installation instructions.

**Q: How do I see waveforms?**
A: Enable `$dumpvars` in testbench, then use `gtkwave firmware/build/spark_mcu_test.vcd`

**Q: Can I use other simulators?**
A: Framework is ready in `simulate.sh` - see its implementation section.

**Q: How do I change clock frequency?**
A: Edit `testbench/spark_mcu_test_tb.v` - parameter CLK_PERIOD

**Q: What about UART baud rate?**
A: Must match in both firmware header and testbench - currently 9600

---

## 🚨 Troubleshooting

### "Command not found: avr-gcc"
```bash
# Install AVR toolchain
sudo apt-get install gcc-avr   # Ubuntu
brew install avr-gcc           # macOS
```
See [SETUP.md](SETUP.md) for detailed instructions.

### "Hex file not found"
```bash
# Build firmware first
make -f Makefile.fw build-fw
```

### "iverilog not found"
```bash
# Install Icarus Verilog
sudo apt-get install iverilog  # Ubuntu
brew install icarus-verilog    # macOS
```

### "Simulation timeout"
```bash
# Increase SIM_TIME in Makefile.fw or testbench
SIM_TIME = 200000000  # ns (default 100ms)
```

See [SETUP.md](SETUP.md) troubleshooting section for more.

---

## 📈 What's Next?

1. **Immediate** (5 min)
   - Run `make -f Makefile.fw verify`
   - See if all 14 tests pass

2. **Short Term** (30 min)
   - Read [QUICKSTART.md](QUICKSTART.md)
   - Understand the basic flow

3. **Medium Term** (1-2 hours)
   - Read full documentation
   - Write custom tests
   - Explore the code

4. **Long Term**
   - Integrate with CI/CD
   - Add more peripherals
   - Extend to your needs

---

## 💡 Key Insights

The system uses a clever approach:

1. **Compile C firmware** with avr-gcc to generate .hex file
2. **Load .hex file** into simulation memory via $readmemh  
3. **Monitor UART output** from MCU in testbench
4. **Capture PASS/FAIL** keywords in simulation
5. **Report results** automatically

This enables **firmware-driven verification** - the firmware itself reports test results!

---

## 📞 Need Help?

| Question | See |
|----------|-----|
| "How do I start?" | [QUICKSTART.md](QUICKSTART.md) |
| "How do I install?" | [SETUP.md](SETUP.md) |
| "How does it work?" | [VERIFICATION_FLOW.md](VERIFICATION_FLOW.md) |
| "What's the design?" | [ARCHITECTURE.md](ARCHITECTURE.md) |
| "Where's file X?" | [FILE_REFERENCE.md](FILE_REFERENCE.md) |
| "What was made?" | [README-VERIFICATION.md](README-VERIFICATION.md) |
| "Is it done?" | [DELIVERY_CHECKLIST.md](DELIVERY_CHECKLIST.md) |

---

## ✅ Status

- ✅ RTL modules created
- ✅ Testbench enhanced
- ✅ Firmware framework complete
- ✅ Test suite implemented (14 tests)
- ✅ Build system automated
- ✅ Documentation comprehensive (4,500+ lines)
- ✅ Ready for production use

**Status: COMPLETE ✅**

---

## 🎯 Remember

```bash
# This one command does everything:
make -f Makefile.fw verify

# Expected output includes:
# [TB] TEST: PASSED
```

If you see that, you're good to go! 🚀

---

## 📖 Full Documentation Map

```
START HERE (this file)
   ↓
QUICKSTART.md (5 min) ——→ Try it now
   ↓
Choose your path:
   ├→ SETUP.md (Installation)
   ├→ VERIFICATION_FLOW.md (Complete guide)
   ├→ ARCHITECTURE.md (Design details)
   ├→ FILE_REFERENCE.md (File details)
   └→ README-VERIFICATION.md (Summary)
   ↓
DELIVERY_CHECKLIST.md (Final confirmation)
```

---

**Welcome to SparkMCU Firmware-Driven Verification!**

Start with: `make -f Makefile.fw verify`

All files are in: `/home/shahrear/OpenLane/designs/SparkMCU/`

Questions? Check the docs or see QUICKSTART.md

---

*Version 1.0 | March 2026 | SparkMCU v1.0*
