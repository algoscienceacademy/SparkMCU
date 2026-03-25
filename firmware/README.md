# ============================================================================
# SparkMCU Firmware - README
# ============================================================================

## Overview

SparkMCU Firmware provides a complete embedded C/assembly software stack for the SparkMCU 8-bit microcontroller (ATmega328P ISA-compatible). It includes:

- **Startup Code**: Interrupt vectors, stack initialization, main entry
- **Device Headers**: Register definitions and memory map
- **Firmware Libraries**: GPIO, UART, Timer, and Delay utilities
- **Example Applications**: Blink, UART Echo, LED Toggle, PWM Demo
- **Build System**: Makefile-based compilation and flashing

## Directory Structure

```
firmware/
├── Makefile              # Build system
├── README.md            # This file
├── include/             # Header files
│   └── spark_mcu.h      # Device definitions
├── lib/                 # Firmware libraries
│   ├── gpio.c           # GPIO control
│   ├── uart.c           # UART/Serial driver
│   ├── delay.c          # Delay functions
│   └── timer.c          # Timer/PWM control
├── src/                 # Application sources
│   ├── startup.S        # Startup code (assembly)
│   ├── blink_main.c     # LED blink example
│   ├── uart_echo_main.c # UART echo example
│   ├── led_toggle_main.c# LED toggle with timer
│   └── timer_demo_main.c # PWM/Timer demo
├── scripts/
│   └── linker.ld        # Linker script
└── build/               # Build artifacts (generated)
```

## Requirements

- **Compiler**: avr-gcc (AVR-GCC Toolchain)
- **Binutils**: avr-binutils (avr-as, avr-ld, avr-objcopy)
- **Programmer**: avrdude (optional, for hardware flashing)
- **Make**: GNU Make

### Installation (Ubuntu/Debian)

```bash
sudo apt-get install avr-libc gcc-avr binutils-avr avrdude
```

### Installation (macOS - Homebrew)

```bash
brew install avr-gcc avrdude
```

## Building

### Build All Examples

```bash
make all
```

### Build Specific Example

```bash
make blink              # LED blink
make uart_echo          # UART echo
make led_toggle         # LED toggle with timer
make timer_demo         # PWM/Timer demo
```

### Show Build Output

```bash
ls -lh build/
```

## Firmware Libraries

### GPIO Library (`lib/gpio.c`)

GPIO control for Ports B, C, D with functions:
- `gpio_init()` - Initialize all ports
- `portb_set(value)` - Set entire Port B
- `portb_set_bit(bit)` - Set single bit
- `portb_clr_bit(bit)` - Clear single bit
- `portb_toggle_bit(bit)` - Toggle single bit
- `portb_read()` - Read Port B input

### UART Library (`lib/uart.c`)

Serial communication at 9600 baud (configurable):
- `uart_init()` - Initialize UART 0
- `uart_tx(data)` - Send byte
- `uart_rx()` - Receive byte (blocking)
- `uart_puts(str)` - Send string
- `uart_puthex8(val)` - Send byte as hex
- `uart_putdec8(val)` - Send byte as decimal
- `uart_rx_nonblock(data)` - Non-blocking receive

### Delay Library (`lib/delay.c`)

Timing functions:
- `delay_us(microseconds)` - Microsecond delay
- `delay_ms(milliseconds)` - Millisecond delay
- `delay_s(seconds)` - Second delay
- `delay_cycles(cycles)` - Cycle-accurate delay

### Timer Library (`lib/timer.c`)

Timer 0 PWM and CTC modes:
- `timer0_init_normal(prescaler)` - Normal (overflow) mode
- `timer0_init_ctc(prescaler, compare)` - Clear-on-compare mode
- `timer0_init_pwm_fast(prescaler)` - Fast PWM mode
- `timer0_set_ocra(value)` - Set Compare A value
- `timer0_enable_compa_int()` - Enable Compare A interrupt

## Examples

### 1. LED Blink

Toggles all Port B LEDs every 500ms.

```bash
make blink
# Output: build/blink.hex, build/blink.elf
```

### 2. UART Echo

Echoes UART input and displays on Port B LEDs.

```bash
make uart_echo
# Connect: GND to GND, RXD (PD0) to TX, TXD (PD1) to RX
# Speed: 9600 baud, 8N1
```

### 3. LED Toggle with Timer

Uses Timer 0 interrupt to toggle LEDs without blocking.

```bash
make led_toggle
# Toggles all LEDs every ~500ms using interrupt
```

### 4. PWM Demo

Generates variable-duty PWM on OC0A/OC0B (16kHz).

```bash
make timer_demo
# Sweeps PWM from 0-255 and back, reports via UART
```

## Flashing to Hardware

### Using avrdude

```bash
make flash APP=blink
```

This requires a compatible programmer (USBasp, STK500, etc.) configured in the Makefile.

### Manual Compilation & Flashing

```bash
avr-gcc -mmcu=atmega328p -Os -Wall -I include \
    -T scripts/linker.ld \
    -o build/blink.elf \
    src/startup.S src/blink_main.c \
    lib/gpio.c lib/delay.c

avr-objcopy -O ihex -R .eeprom build/blink.elf build/blink.hex

avrdude -p atmega328p -c usbasp -U flash:w:build/blink.hex:i
```

## Device Specifications

**SparkMCU (ATmega328P ISA-Compatible)**

- **Processor**: 8-bit AVR core @ 16 MHz
- **Flash Memory**: 32 KB (Program)
- **SRAM**: 2.25 KB (Data + Stack)
- **EEPROM**: 1 KB
- **GPIO**: 
  - Port B: 8 pins
  - Port C: 6 pins
  - Port D: 8 pins
- **UART**: 1x USART0 (9600 baud default)
- **SPI**: 1x SPI Master
- **Timers**: 1x 8-bit Timer/Counter 0 with PWM
- **Interrupts**: INT0, INT1, PCINT0-2, WDT, Timer, UART, SPI, etc.

## Memory Map

```
Flash (32 KB):
  0x0000 - 0x0035: Interrupt vectors (56 bytes)
  0x0036 - 0x7FFF: Program code & data

SRAM (2.25 KB):
  0x0060 - 0x00FF: I/O Registers & General Purpose RAM
  0x0100 - 0x08FF: SRAM

EEPROM (1 KB):
  0x0000 - 0x03FF: Electrically Erasable Programmable ROM
```

## Debugging

### Show Object Size

```bash
make size APP=blink
```

### Disassemble Binary

```bash
make dis APP=blink
# Creates: build/blink.dis
```

### AVR Simulator (simavr)

```bash
simavr -m atmega328p build/blink.elf
```

## Extending the Firmware

### Adding a New Example

1. Create `src/my_app_main.c`:

```c
#include <avr/io.h>

int main(void) {
    // Your code here
    return 0;
}
```

2. Add target to `Makefile`:

```makefile
my_app: $(OUT_DIR)/my_app.elf $(OUT_DIR)/my_app.hex

$(OUT_DIR)/my_app.elf: $(OUT_DIR)/startup.o $(OUT_DIR)/my_app_main.o ...
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
```

3. Build:

```bash
make my_app
```

### Adding a New Library

1. Create `lib/my_lib.c` with functions
2. Create `lib/my_lib.h` with declarations
3. Add to `Makefile` `TARGETS` or specific build rules

## Troubleshooting

### Compilation Errors

- Ensure avr-gcc is installed: `avr-gcc --version`
- Check paths in Makefile match your system
- Verify all source files exist

### Linking Errors

- Verify linker script (`scripts/linker.ld`) is correct
- Check symbol definitions in startup code
- Ensure all required libraries are linked

### Flash Size Too Large

- Use `-Os` optimization (Makefile default)
- Remove unused code from examples
- Use shorter function names

## References

- [AVR GCC Manual](https://www.nongnu.org/avr-libc/user-manual/)
- [ATmega328P Datasheet](http://www.atmel.com/devices/ATMEGA328P.aspx)
- [avrdude Documentation](http://savannah.nongnu.org/projects/avrdude)

## License

SparkMCU Firmware is open-source and provided as-is for educational and embedded development purposes.

---

**Happy Embedded Coding! 🚀**
