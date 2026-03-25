# ============================================================================
# SparkMCU - Firmware Build System
# ============================================================================
# Target: AVR-Compatible 8-bit Microcontroller (ATmega328P ISA)
# Toolchain: AVR-GCC / AVR-Binutils
# ============================================================================

# Configuration
MCU          = atmega328p
FREQ         = 16000000
BAUD         = 9600
OPTIMIZATION = -Os

# Directories
SRC_DIR      = src
INC_DIR      = include
LIB_DIR      = lib
OUT_DIR      = build
SCRIPT_DIR   = scripts

# Tools
CC           = avr-gcc
AS           = avr-as
LD           = avr-ld
OBJCOPY      = avr-objcopy
OBJDUMP      = avr-objdump
SIZE         = avr-size
DUDE         = avrdude

# Flags
CFLAGS       = -mmcu=$(MCU) $(OPTIMIZATION) -Wall -Wextra -I$(INC_DIR) -DF_CPU=$(FREQ)
ASFLAGS      = -mmcu=$(MCU)
LDFLAGS      = -T$(SCRIPT_DIR)/linker.ld
DUDEFLAGS    = -p $(MCU) -c usbasp -B 1

# Source files
C_SRCS       = $(wildcard $(SRC_DIR)/*.c) $(wildcard $(LIB_DIR)/*.c)
ASM_SRCS     = $(wildcard $(SRC_DIR)/*.S) $(wildcard $(LIB_DIR)/*.S)
OBJS         = $(C_SRCS:$(SRC_DIR)/%.c=$(OUT_DIR)/%.o) \
               $(C_SRCS:$(LIB_DIR)/%.c=$(OUT_DIR)/lib_%.o) \
               $(ASM_SRCS:$(SRC_DIR)/%.S=$(OUT_DIR)/%.o) \
               $(ASM_SRCS:$(LIB_DIR)/%.S=$(OUT_DIR)/lib_%.o)

# Main targets
TARGETS      = blink uart_echo led_toggle timer_demo

# Default target
.PHONY: all clean help flash size

all: $(TARGETS)

help:
	@echo "=========================================="
	@echo "  SparkMCU Firmware Build System"
	@echo "=========================================="
	@echo "Targets:"
	@echo "  make blink          - Blink LED example"
	@echo "  make uart_echo      - UART echo example"
	@echo "  make led_toggle     - LED toggle with timer"
	@echo "  make timer_demo     - Timer interrupt demo"
	@echo "  make all            - Build all examples"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make flash APP=X    - Flash APP to chip"
	@echo "  make size APP=X     - Show size info"
	@echo "=========================================="

# Create build directory
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Compile C sources
$(OUT_DIR)/%.o: $(SRC_DIR)/%.c | $(OUT_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OUT_DIR)/lib_%.o: $(LIB_DIR)/%.c | $(OUT_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble ASM sources
$(OUT_DIR)/%.o: $(SRC_DIR)/%.S | $(OUT_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OUT_DIR)/lib_%.o: $(LIB_DIR)/%.S | $(OUT_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Build blink example
blink: $(OUT_DIR)/blink.elf $(OUT_DIR)/blink.hex
	@echo "Built: blink"

$(OUT_DIR)/blink.elf: $(OUT_DIR)/startup.o $(OUT_DIR)/blink_main.o $(OUT_DIR)/lib_gpio.o $(OUT_DIR)/lib_delay.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(OUT_DIR)/blink.hex: $(OUT_DIR)/blink.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Build UART echo example
uart_echo: $(OUT_DIR)/uart_echo.elf $(OUT_DIR)/uart_echo.hex
	@echo "Built: uart_echo"

$(OUT_DIR)/uart_echo.elf: $(OUT_DIR)/startup.o $(OUT_DIR)/uart_echo_main.o $(OUT_DIR)/lib_uart.o $(OUT_DIR)/lib_gpio.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(OUT_DIR)/uart_echo.hex: $(OUT_DIR)/uart_echo.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Build LED toggle example
led_toggle: $(OUT_DIR)/led_toggle.elf $(OUT_DIR)/led_toggle.hex
	@echo "Built: led_toggle"

$(OUT_DIR)/led_toggle.elf: $(OUT_DIR)/startup.o $(OUT_DIR)/led_toggle_main.o $(OUT_DIR)/lib_gpio.o $(OUT_DIR)/lib_timer.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(OUT_DIR)/led_toggle.hex: $(OUT_DIR)/led_toggle.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Build timer demo example
timer_demo: $(OUT_DIR)/timer_demo.elf $(OUT_DIR)/timer_demo.hex
	@echo "Built: timer_demo"

$(OUT_DIR)/timer_demo.elf: $(OUT_DIR)/startup.o $(OUT_DIR)/timer_demo_main.o $(OUT_DIR)/lib_timer.o $(OUT_DIR)/lib_uart.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(OUT_DIR)/timer_demo.hex: $(OUT_DIR)/timer_demo.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Flash target
ifdef APP
flash: $(OUT_DIR)/$(APP).hex
	$(DUDE) $(DUDEFLAGS) -U flash:w:$<:i
	@echo "Flashed: $(APP)"
else
flash:
	@echo "Usage: make flash APP=<target_name>"
	@echo "Example: make flash APP=blink"
endif

# Show size
ifdef APP
size: $(OUT_DIR)/$(APP).elf
	$(SIZE) -C --mcu=$(MCU) $<
else
size:
	@echo "Usage: make size APP=<target_name>"
	@echo "Example: make size APP=blink"
endif

# Disassemble
ifdef APP
dis: $(OUT_DIR)/$(APP).elf
	$(OBJDUMP) -d $< > $(OUT_DIR)/$(APP).dis
	@echo "Disassembly: $(OUT_DIR)/$(APP).dis"
else
dis:
	@echo "Usage: make dis APP=<target_name>"
endif

# Clean
clean:
	rm -rf $(OUT_DIR)
	@echo "Cleaned build artifacts"
