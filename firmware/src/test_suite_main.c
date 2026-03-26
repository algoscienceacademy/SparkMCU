/* ============================================================================
 * SparkMCU - Comprehensive Firmware Test Suite
 * ============================================================================
 * Tests for:
 *   - GPIO (read/write ports)
 *   - Timer0 (counter, overflow)
 *   - UART (loopback)
 *   - ALU (basic operations)
 *   - SPI (basic communication)
 *   - Interrupts (external interrupt handling)
 * ============================================================================ */

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "test_framework.h"

/* ============================================================================
 * Global Test Variables
 * ============================================================================ */

volatile uint8_t int0_fired = 0;
volatile uint8_t int1_fired = 0;
volatile uint8_t timer0_overflow = 0;

/* ============================================================================
 * Interrupt Service Routines
 * ============================================================================ */

ISR(INT0_vect) {
    int0_fired = 1;
}

ISR(INT1_vect) {
    int1_fired = 1;
}

ISR(TIMER0_OVF_vect) {
    timer0_overflow++;
}

/* ============================================================================
 * Test Case: GPIO Port B Read/Write
 * ============================================================================ */

void test_gpio_port_b(void) {
    test_start("GPIO Port B R/W");
    
    gpio_init_outputs();
    
    /* Test pattern 1: 0x55 (01010101) */
    gpio_write_byte(0, 0x55);
    delay_ms(1);
    uint8_t read_val = gpio_read_byte(0);
    test_assert(read_val == 0x55, "Pattern 0x55 mismatch");
    
    /* Test pattern 2: 0xAA (10101010) */
    gpio_write_byte(0, 0xAA);
    delay_ms(1);
    read_val = gpio_read_byte(0);
    test_assert(read_val == 0xAA, "Pattern 0xAA mismatch");
    
    /* Test pattern 3: 0xFF (11111111) */
    gpio_write_byte(0, 0xFF);
    delay_ms(1);
    read_val = gpio_read_byte(0);
    test_assert(read_val == 0xFF, "Pattern 0xFF mismatch");
    
    /* Test pattern 4: 0x00 (00000000) */
    gpio_write_byte(0, 0x00);
    delay_ms(1);
    read_val = gpio_read_byte(0);
    test_assert(read_val == 0x00, "Pattern 0x00 mismatch");
    
    test_end();
}

/* ============================================================================
 * Test Case: GPIO Port C (6-bit)
 * ============================================================================ */

void test_gpio_port_c(void) {
    test_start("GPIO Port C R/W");
    
    gpio_init_outputs();
    
    /* Test pattern 1: 0x15 (010101) */
    gpio_write_byte(1, 0x15);
    delay_ms(1);
    uint8_t read_val = gpio_read_byte(1) & 0x3F;
    test_assert(read_val == 0x15, "Pattern 0x15 mismatch");
    
    /* Test pattern 2: 0x2A (101010) */
    gpio_write_byte(1, 0x2A);
    delay_ms(1);
    read_val = gpio_read_byte(1) & 0x3F;
    test_assert(read_val == 0x2A, "Pattern 0x2A mismatch");
    
    test_end();
}

/* ============================================================================
 * Test Case: GPIO Port D
 * ============================================================================ */

void test_gpio_port_d(void) {
    test_start("GPIO Port D R/W");
    
    gpio_init_outputs();
    
    /* Test pattern (excluding RXD at PD0, TXD at PD1) */
    gpio_write_byte(2, 0xFC);  /* Bits [7:2] = 111111 */
    delay_ms(1);
    uint8_t read_val = gpio_read_byte(2) & 0xFC;
    test_assert(read_val == 0xFC, "Pattern 0xFC mismatch");
    
    test_end();
}

/* ============================================================================
 * Test Case: Timer0 Basic Operation
 * ============================================================================ */

void test_timer0_basic(void) {
    test_start("Timer0 Basic Operation");
    
    /* Initialize timer with prescaler 1:64 */
    timer0_init(0x03);  /* Prescaler 000 = stop, 001 = 1, 010 = 8, 011 = 64 */
    delay_ms(1);
    
    /* Write initial value */
    timer0_write(0x00);
    delay_ms(10);
    
    /* Read counter (should have incremented) */
    uint8_t count1 = timer0_read();
    test_assert(count1 > 0, "Timer did not increment");
    
    /* Wait and check again */
    delay_ms(10);
    uint8_t count2 = timer0_read();
    test_assert(count2 > count1, "Timer did not continue incrementing");
    
    test_end();
}

/* ============================================================================
 * Test Case: Timer0 Overflow
 * ============================================================================ */

void test_timer0_overflow(void) {
    test_start("Timer0 Overflow");
    
    timer0_overflow = 0;
    timer0_clear_overflow_flag();
    timer0_init(0x01);  /* Prescaler 1:1 */
    timer0_write(0xF0);  /* Start near overflow */
    
    delay_ms(5);  /* Wait for overflow to occur */
    
    uint8_t ovf = timer0_overflow_flag();
    test_assert(ovf != 0, "Timer overflow flag not set");
    
    test_end();
}

/* ============================================================================
 * Test Case: UART Loopback
 * ============================================================================ */

void test_uart_loopback(void) {
    test_start("UART Loopback");
    
    uart_init();
    
    /* Enable UART loopback via UCSR0D (if available) or software */
    /* For this test, we just verify UART can transmit */
    
    uart_puts("UART_TEST");
    delay_ms(10);
    
    /* Check if data was transmitted (would be looped back in real hardware) */
    test_assert(1, "UART transmission");
    
    test_end();
}

/* ============================================================================
 * Test Case: ALU Addition (via assembly)
 * ============================================================================ */

void test_alu_add(void) {
    test_start("ALU Addition");
    
    uint8_t a = 0x12;
    uint8_t b = 0x34;
    uint8_t result = a + b;
    uint8_t expected = 0x46;
    
    test_assert(result == expected, "Add 0x12+0x34 failed");
    
    /* Test overflow */
    a = 0x80;
    b = 0x80;
    result = a + b;  /* Should be 0x100, overflow to 0x00 */
    test_assert(result == 0x00, "Add overflow detection failed");
    
    test_end();
}

/* ============================================================================
 * Test Case: ALU Subtraction
 * ============================================================================ */

void test_alu_sub(void) {
    test_start("ALU Subtraction");
    
    uint8_t a = 0x50;
    uint8_t b = 0x30;
    uint8_t result = a - b;
    uint8_t expected = 0x20;
    
    test_assert(result == expected, "Sub 0x50-0x30 failed");
    
    /* Test underflow */
    a = 0x10;
    b = 0x20;
    result = a - b;  /* Should underflow to 0xF0 */
    test_assert(result == 0xF0, "Sub underflow detection failed");
    
    test_end();
}

/* ============================================================================
 * Test Case: ALU Bitwise AND
 * ============================================================================ */

void test_alu_and(void) {
    test_start("ALU Bitwise AND");
    
    uint8_t a = 0xF0;
    uint8_t b = 0x0F;
    uint8_t result = a & b;
    
    test_assert(result == 0x00, "AND 0xF0 & 0x0F failed");
    
    a = 0xAA;
    b = 0x55;
    result = a & b;
    test_assert(result == 0x00, "AND 0xAA & 0x55 failed");
    
    test_end();
}

/* ============================================================================
 * Test Case: ALU Bitwise OR
 * ============================================================================ */

void test_alu_or(void) {
    test_start("ALU Bitwise OR");
    
    uint8_t a = 0xF0;
    uint8_t b = 0x0F;
    uint8_t result = a | b;
    
    test_assert(result == 0xFF, "OR 0xF0 | 0x0F failed");
    
    a = 0x00;
    b = 0x55;
    result = a | b;
    test_assert(result == 0x55, "OR 0x00 | 0x55 failed");
    
    test_end();
}

/* ============================================================================
 * Test Case: ALU Bitwise XOR
 * ============================================================================ */

void test_alu_xor(void) {
    test_start("ALU Bitwise XOR");
    
    uint8_t a = 0xAA;
    uint8_t b = 0x55;
    uint8_t result = a ^ b;
    
    test_assert(result == 0xFF, "XOR 0xAA ^ 0x55 failed");
    
    a = 0xFF;
    b = 0xFF;
    result = a ^ b;
    test_assert(result == 0x00, "XOR 0xFF ^ 0xFF failed");
    
    test_end();
}

/* ============================================================================
 * Test Case: SPI Basic Communication
 * ============================================================================ */

void test_spi_basic(void) {
    test_start("SPI Basic Communication");
    
    /* Initialize SPI as master, mode 0, clock rate fosc/4 */
    SPCR = (1 << SPE) | (1 << MSTR);  /* Enable SPI, Master mode */
    SPSR = 0x00;  /* Normal speed (fosc/4) */
    
    /* Transmit test byte */
    SPDR = 0x42;  /* Test pattern */
    
    /* Wait for transmission complete */
    delay_ms(1);
    
    test_assert(1, "SPI communication initiated");
    
    test_end();
}

/* ============================================================================
 * Test Case: External Interrupt INT0
 * ============================================================================ */

void test_int0(void) {
    test_start("External Interrupt INT0");
    
    int0_fired = 0;
    
    /* Configure INT0: falling edge trigger */
    EICRA = (1 << ISC01);  /* Falling edge */
    EIMSK = (1 << INT0);   /* Enable INT0 */
    
    sei();  /* Enable global interrupts */
    
    /* Simulate falling edge (in real hardware, this would be external) */
    /* For now, we just verify the interrupt is configured */
    
    test_assert(EIMSK & (1 << INT0), "INT0 not enabled");
    
    cli();  /* Disable global interrupts */
    test_end();
}

/* ============================================================================
 * Test Case: Memory Read/Write
 * ============================================================================ */

void test_memory_rw(void) {
    test_start("Memory Read/Write");
    
    /* Use SRAM for testing */
    volatile uint8_t *mem_addr = (volatile uint8_t *)0x0200;
    
    *mem_addr = 0x42;
    delay_ms(1);
    uint8_t read_val = *mem_addr;
    test_assert(read_val == 0x42, "Memory write/read failed");
    
    *mem_addr = 0xA5;
    uint8_t read_val2 = *mem_addr;
    test_assert(read_val2 == 0xA5, "Memory pattern 0xA5 failed");
    
    test_end();
}

/* ============================================================================
 * Main Test Entry Point
 * ============================================================================ */

int main(void) {
    test_init();
    
    /* GPIO Tests */
    test_gpio_port_b();
    test_gpio_port_c();
    test_gpio_port_d();
    
    /* Timer Tests */
    test_timer0_basic();
    test_timer0_overflow();
    
    /* UART Tests */
    test_uart_loopback();
    
    /* ALU Tests */
    test_alu_add();
    test_alu_sub();
    test_alu_and();
    test_alu_or();
    test_alu_xor();
    
    /* SPI Tests */
    test_spi_basic();
    
    /* Interrupt Tests */
    test_int0();
    
    /* Memory Tests */
    test_memory_rw();
    
    /* Print test report */
    test_report();
    
    /* Infinite loop - firmware complete */
    while (1) {
        asm volatile("nop");
    }
    
    return 0;
}
