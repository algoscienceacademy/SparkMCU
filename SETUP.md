# SparkMCU Firmware-Driven Verification: Setup & Installation

## System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 18.04+), macOS 10.13+, or Windows with WSL2
- **RAM**: 2GB (4GB+ recommended)
- **Disk**: 500MB free space
- **CPU**: Any modern processor

### Recommended Setup
- **OS**: Ubuntu 20.04 LTS
- **RAM**: 4GB-8GB
- **Disk**: 1GB+ SSD
- **CPU**: Intel i5/i7 or equivalent

---

## Installation Guide

### Option 1: Ubuntu/Debian (Recommended)

#### 1.1 Install AVR Toolchain

```bash
# Update package lists
sudo apt-get update

# Install AVR GCC and associated tools
sudo apt-get install -y \
    gcc-avr \
    binutils-avr \
    avr-libc \
    avrdude

# Verify installation
avr-gcc --version
```

**Expected output:**
```
avr-gcc (GCC) 5.4.0
...
```

#### 1.2 Install Verilog Simulator

```bash
# Install Icarus Verilog
sudo apt-get install -y iverilog

# Verify installation
iverilog -version
```

**Expected output:**
```
Icarus Verilog version 12.0 (devel)
```

#### 1.3 Install Optional Tools

```bash
# For waveform viewing
sudo apt-get install -y gtkwave

# For development
sudo apt-get install -y git make build-essential
```

#### One-Command Installation

```bash
sudo apt-get update && sudo apt-get install -y \
    gcc-avr binutils-avr avr-libc \
    iverilog gtkwave make
```

---

### Option 2: macOS (via Homebrew)

#### 2.1 Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2.2 Install AVR Toolchain

```bash
# Add AVR tap
brew tap osx-cross/avr

# Install AVR GCC
brew install avr-gcc

# Install AVR libc
brew install avr-libc

# Verify
avr-gcc --version
```

#### 2.3 Install Verilog Simulator

```bash
# Install Icarus Verilog
brew install icarus-verilog

# Verify
iverilog -version
```

#### 2.4 Install Optional Tools

```bash
# For waveform viewing
brew install gtkwave

# For development tools
brew install make git
```

#### One-Command Installation

```bash
brew tap osx-cross/avr && \
brew install avr-gcc avr-libc icarus-verilog gtkwave
```

---

### Option 3: Windows (with WSL2)

#### 3.1 Enable WSL2

```powershell
# Run as Administrator
wsl --install
# Restart computer
wsl --set-default-version 2
```

#### 3.2 Install Ubuntu in WSL2

```powershell
wsl --install -d ubuntu-20.04
# Set default user
ubuntu-20.04 config --default-user username
```

#### 3.3 Setup Inside WSL2

Open WSL2 terminal and run Ubuntu/Debian installation from Option 1:

```bash
sudo apt-get update && sudo apt-get install -y \
    gcc-avr binutils-avr avr-libc \
    iverilog gtkwave make
```

#### 3.4 Access SparkMCU Files

From WSL2:
```bash
# SparkMCU is at /mnt/c/Users/YourUsername/...
cd /mnt/c/Users/YourUsername/path/to/SparkMCU
```

---

### Option 4: Docker (Containerized Environment)

Create `Dockerfile`:

```dockerfile
FROM ubuntu:20.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    gcc-avr \
    binutils-avr \
    avr-libc \
    iverilog \
    gtkwave \
    git \
    make \
    vim

# Set working directory
WORKDIR /workspace

# Entry point
CMD ["/bin/bash"]
```

Build and run:

```bash
# Build Docker image
docker build -t sparkmcu-verilog .

# Run container with SparkMCU mounted
docker run -it -v $(pwd):/workspace sparkmcu-verilog

# Inside container:
cd /workspace
make -f Makefile.fw verify
```

---

## Verify Installation

### Check All Tools

Create `check_setup.sh`:

```bash
#!/bin/bash

echo "Checking SparkMCU verification environment..."
echo ""

# Check AVR GCC
if command -v avr-gcc &> /dev/null; then
    echo "✓ avr-gcc: $(avr-gcc --version | head -n1)"
else
    echo "✗ avr-gcc: NOT FOUND"
    exit 1
fi

# Check AVR objcopy
if command -v avr-objcopy &> /dev/null; then
    echo "✓ avr-objcopy: installed"
else
    echo "✗ avr-objcopy: NOT FOUND"
    exit 1
fi

# Check AVR size
if command -v avr-size &> /dev/null; then
    echo "✓ avr-size: installed"
else
    echo "✗ avr-size: NOT FOUND"
    exit 1
fi

# Check iverilog
if command -v iverilog &> /dev/null; then
    echo "✓ iverilog: $(iverilog -version 2>&1 | head -n1)"
else
    echo "✗ iverilog: NOT FOUND"
    exit 1
fi

# Check vvp
if command -v vvp &> /dev/null; then
    echo "✓ vvp: installed"
else
    echo "✗ vvp: NOT FOUND"
    exit 1
fi

# Check make
if command -v make &> /dev/null; then
    echo "✓ make: installed"
else
    echo "✗ make: NOT FOUND"
    exit 1
fi

# Check gtkwave (optional)
if command -v gtkwave &> /dev/null; then
    echo "✓ gtkwave: installed (optional)"
else
    echo "○ gtkwave: not found (optional, for waveform viewing)"
fi

echo ""
echo "Setup verification complete!"
```

Run:
```bash
bash check_setup.sh
```

Expected output:
```
✓ avr-gcc: avr-gcc (GCC) 5.4.0
✓ avr-objcopy: installed
✓ avr-size: installed
✓ iverilog: Icarus Verilog version 12.0
✓ vvp: installed
✓ make: installed
○ gtkwave: installed (optional)

Setup verification complete!
```

---

## Project Setup

### 1. Clone/Download SparkMCU

```bash
# If using git
git clone <sparkmcu-repo-url>
cd SparkMCU

# Or extract from tar
tar -xzf sparkmcu.tar.gz
cd SparkMCU
```

### 2. Verify Directory Structure

```bash
# Check essential directories
[ -d firmware/src ] && echo "✓ firmware/src" || echo "✗ firmware/src"
[ -d firmware/include ] && echo "✓ firmware/include" || echo "✗ firmware/include"
[ -d rtl ] && echo "✓ rtl" || echo "✗ rtl"
[ -d testbench ] && echo "✓ testbench" || echo "✗ testbench"
[ -f Makefile.fw ] && echo "✓ Makefile.fw" || echo "✗ Makefile.fw"
```

### 3. Create Build Directory

```bash
mkdir -p firmware/build
chmod 755 firmware/build
```

### 4. Make Scripts Executable

```bash
chmod +x build_firmware.sh simulate.sh
```

---

## First Run

### Step 1: Build Firmware

```bash
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
[SUCCESS] Build complete!
Hex file ready at: firmware/build/test_suite_main.hex
```

### Step 2: Run Simulation

```bash
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
[TEST] GPIO Port B R/W ... PASS
[TEST] GPIO Port C R/W ... PASS
...
[TB] TEST: PASSED
[SUCCESS] Simulation completed successfully
```

### Step 3: Complete Verification

```bash
make -f Makefile.fw verify
```

---

## Troubleshooting Installation

### Problem: "avr-gcc: command not found"

**Solution 1 - Reinstall:**
```bash
# Ubuntu
sudo apt-get install --reinstall gcc-avr

# macOS
brew reinstall avr-gcc
```

**Solution 2 - Add to PATH:**
```bash
# Find location
which avr-gcc

# Add to .bashrc or .zshrc if needed
export PATH=/usr/bin:$PATH
```

### Problem: "iverilog: command not found"

**Solution:**
```bash
# Ubuntu
sudo apt-get install --reinstall iverilog

# macOS
brew reinstall icarus-verilog
```

### Problem: Permission denied on shell scripts

**Solution:**
```bash
chmod +x build_firmware.sh simulate.sh
ls -l build_firmware.sh  # Should show rwx------
```

### Problem: "Hex file not found" during simulation

**Solution:**
```bash
# Build firmware first
./build_firmware.sh test_suite_main

# Then simulate
./simulate.sh iverilog test_suite_main
```

### Problem: "iVerilog compilation failed"

**Solution:**
```bash
# Check for Verilog syntax errors
iverilog -v rtl/spark_mcu_top.v 2>&1 | head -20

# Verify all RTL files exist
ls -1 rtl */*.v | wc -l  # Should be > 10
```

---

## Development Tools (Optional)

### GTKWave for Waveform Viewing

```bash
# Install
sudo apt-get install gtkwave  # Ubuntu
brew install gtkwave          # macOS

# Enable waveform in testbench
# Uncomment in testbench/spark_mcu_test_tb.v:
# $dumpfile("spark_mcu_test.vcd");
# $dumpvars(0, spark_mcu_test_tb);

# View waveform
gtkwave firmware/build/spark_mcu_test.vcd
```

### Text Editors

For editing C firmware:
```bash
# Install VS Code
sudo apt-get install code  # Ubuntu

# Or use Vim/Nano (already installed)
vim firmware/src/test_suite_main.c
```

### Git for Version Control

```bash
# Install
sudo apt-get install git  # Ubuntu
brew install git          # macOS

# Initialize repo
cd SparkMCU
git init
git add .
git commit -m "Initial commit"
```

---

## IDE Integration

### VS Code Setup

1. **Install Extensions**:
   - C/C++ (Microsoft)
   - Verilog-HDL/SystemVerilog (Vivado)
   - Make Task Provider

2. **Create `.vscode/settings.json`**:
```json
{
    "C_Cpp.default.incPathSource": "workspace",
    "C_Cpp.default.includePath": [
        "${workspaceFolder}/firmware/include"
    ],
    "C_Cpp.default.defines": [
        "F_CPU=16000000UL"
    ]
}
```

3. **Create `.vscode/tasks.json`**:
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Firmware",
            "type": "shell",
            "command": "make",
            "args": ["-f", "Makefile.fw", "build-fw"],
            "group": {"kind": "build", "isDefault": true}
        },
        {
            "label": "Run Simulation",
            "type": "shell",
            "command": "make",
            "args": ["-f", "Makefile.fw", "simulate"]
        }
    ]
}
```

### Vivado Integration

For synthesis and implementation:

```tcl
# Create project
create_project spark_mcu

# Add RTL files
add_files rtl/*.v rtl/*/*.v

# Set target device
set_property part sky130_A (get_projects)

# Run synthesis
synth_design -top spark_mcu_top

# Run place & route
opt_design
place_design
route_design
```

---

## Next Steps After Setup

1. ✅ **Verify Installation**: Run check_setup.sh
2. ✅ **First Build**: Execute `make -f Makefile.fw verify`
3. 📖 **Read Documentation**: Open [QUICKSTART.md](QUICKSTART.md)
4. 🧪 **Create Tests**: Write custom test cases
5. 🔄 **Integrate**: Add to CI/CD pipeline

---

## Getting Help

### Documentation Files

| File | Purpose |
|------|---------|
| [QUICKSTART.md](QUICKSTART.md) | 5-minute quick start |
| [VERIFICATION_FLOW.md](VERIFICATION_FLOW.md) | Complete detailed guide |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Internal design details |
| [firmware/README.md](firmware/README.md) | Firmware documentation |

### Common Issues

```bash
# Check everything
bash check_setup.sh

# Clean rebuild
make -f Makefile.fw clean
make -f Makefile.fw verify

# View detailed output
make -f Makefile.fw build-fw TEST_NAME=test_suite_main
```

---

## Support & Resources

- **SparkMCU Project**: https://github.com/...
- **AVR Tools Docs**: https://www.microchip.com/
- **Icarus Verilog**: http://www.icarus.com/
- **iVerilog GitHub**: https://github.com/steveicarus/iverilog

---

**Version**: 1.0 | **Last Updated**: March 2026 | **SparkMCU v1.0**
