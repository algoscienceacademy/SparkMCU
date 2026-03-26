/* ============================================================================
 * SparkMCU - Firmware Test Framework
 * ============================================================================
 * Test reporting system with UART output for PASS/FAIL results
 * Targets: SparkMCU (ATmega328P ISA compatible)
 * ============================================================================ */

#ifndef __TEST_FRAMEWORK_H__
#define __TEST_FRAMEWORK_H__

#include <stdint.h>
#include <string.h>
#include <avr/io.h>
#include <avr/interrupt.h>

/* ============================================================================
 * UART Functions (for test reporting)
 * ============================================================================ */

#define F_CPU       16000000UL
#define UART_BAUD   9600
#define UART_UBRR   ((F_CPU / 16 / UART_BAUD) - 1)

static volatile uint8_t uart_initialized = 0;

static inline void uart_init(void) {
    if (uart_initialized) return;
    
    /* Set baud rate */
    UBRR0H = (uint8_t)(UART_UBRR >> 8);
    UBRR0L = (uint8_t)(UART_UBRR & 0xFF);

    /* Enable receiver and transmitter */
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);

    /* Set frame format: 8 data bits, 1 stop bit, no parity */
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
    
    uart_initialized = 1;
}

static inline void uart_tx_byte(uint8_t data) {
    /* Wait for empty transmit buffer */
    while (!(UCSR0A & (1 << UDRE0)));
    UDR0 = data;
}

static inline void uart_puts(const char *str) {
    while (*str) {
        uart_tx_byte(*str++);
    }
}

static inline void uart_put_hex(uint8_t val) {
    const char hex[] = "0123456789ABCDEF";
    uart_tx_byte(hex[(val >> 4) & 0x0F]);
    uart_tx_byte(hex[val & 0x0F]);
}

static inline void uart_put_hex16(uint16_t val) {
    uart_put_hex((val >> 8) & 0xFF);
    uart_put_hex(val & 0xFF);
}

/* ============================================================================
 * Test Framework Functions
 * ============================================================================ */

static volatile uint16_t test_pass_count = 0;
static volatile uint16_t test_fail_count = 0;
static volatile uint8_t current_test_status = 1;

void test_init(void) {
    uart_init();
    test_pass_count = 0;
    test_fail_count = 0;
    uart_puts("\r\n");
    uart_puts("================================\r\n");
    uart_puts("SparkMCU Firmware Test Suite\r\n");
    uart_puts("================================\r\n");
}

void test_start(const char *test_name) {
    uart_puts("\r\n[TEST] ");
    uart_puts(test_name);
    uart_puts(" ... ");
    current_test_status = 1;
}

void test_assert(uint8_t condition, const char *msg) {
    if (!condition) {
        current_test_status = 0;
        uart_puts("FAIL: ");
        uart_puts(msg);
        uart_puts("\r\n");
    }
}

void test_end(void) {
    if (current_test_status) {
        uart_puts("PASS\r\n");
        test_pass_count++;
    } else {
        uart_puts("FAIL\r\n");
        test_fail_count++;
    }
}

void test_report(void) {
    uint16_t total = test_pass_count + test_fail_count;
    uart_puts("\r\n");
    uart_puts("================================\r\n");
    uart_puts("Test Results:\r\n");
    uart_puts("================================\r\n");
    uart_puts("PASS: ");
    uart_put_hex16(test_pass_count);
    uart_puts("\r\n");
    uart_puts("FAIL: ");
    uart_put_hex16(test_fail_count);
    uart_puts("\r\n");
    uart_puts("TOTAL: ");
    uart_put_hex16(total);
    uart_puts("\r\n");
    
    if (test_fail_count == 0) {
        uart_puts("STATUS: ALL TESTS PASSED\r\n");
    } else {
        uart_puts("STATUS: SOME TESTS FAILED\r\n");
    }
    uart_puts("================================\r\n");
}

/* ============================================================================
 * GPIO Test Utilities
 * ============================================================================ */

void gpio_init_outputs(void) {
    DDRB = 0xFF;  /* Port B all outputs */
    DDRC = 0x3F;  /* Port C[5:0] outputs */
    DDRD = 0xFE;  /* Port D[7:1] outputs, PD0 is RXD (input) */
    
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
}

void gpio_write_byte(uint8_t port, uint8_t value) {
    switch (port) {
        case 0: PORTB = value; break;
        case 1: PORTC = value & 0x3F; break;
        case 2: PORTD = value; break;
    }
}

uint8_t gpio_read_byte(uint8_t port) {
    switch (port) {
        case 0: return PINB;
        case 1: return PINC & 0x3F;
        case 2: return PIND;
        default: return 0;
    }
}

/* ============================================================================
 * Timer Test Utilities
 * ============================================================================ */

void timer0_init(uint8_t prescaler) {
    /* Set prescaler */
    TCCR0B = prescaler & 0x07;
    /* Clear flag */
    TIFR0 = (1 << TOV0);
}

uint8_t timer0_read(void) {
    return TCNT0;
}

void timer0_write(uint8_t value) {
    TCNT0 = value;
}

uint8_t timer0_overflow_flag(void) {
    return (TIFR0 >> TOV0) & 1;
}

void timer0_clear_overflow_flag(void) {
    TIFR0 = (1 << TOV0);
}

/* ============================================================================
 * Delay Functions
 * ============================================================================ */

void delay_ms(uint16_t ms) {
    /* Simple busy-wait delay */
    /* At 16 MHz: 16 cycles per microsecond, approximately 16000 per millisecond */
    uint16_t i, j;
    for (i = 0; i < ms; i++)
        for (j = 0; j < 123; j++)
            asm volatile("nop");
}

/* ============================================================================
 * ALU Test Utilities
 * ============================================================================ */

/* Define virtual ALU registers via special memory locations */
#define ALU_A       (*((volatile uint8_t *)0x0100))  /* R0 via memory */
#define ALU_B       (*((volatile uint8_t *)0x0101))  /* R1 via memory */
#define ALU_RESULT  (*((volatile uint8_t *)0x0102))  /* R2 via memory */

#endif /* __TEST_FRAMEWORK_H__ */
