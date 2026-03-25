/* ============================================================================
 * SparkMCU - UART Library
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: UART/USART serial communication driver
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

#ifndef F_CPU
#define F_CPU   16000000UL
#endif

#ifndef UART_BAUD
#define UART_BAUD   9600
#endif

#define UART_UBRR_VAL   ((F_CPU / 16 / UART_BAUD) - 1)

/* ============================================================================
 * UART Initialization
 * ============================================================================ */

void uart_init(void) {
    /* Set baud rate */
    UBRR0H = (uint8_t)(UART_UBRR_VAL >> 8);
    UBRR0L = (uint8_t)(UART_UBRR_VAL);

    /* Enable receiver and transmitter */
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);

    /* Set frame format: 8 data bits, 1 stop bit, no parity (8N1) */
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

/* ============================================================================
 * Transmit Functions
 * ============================================================================ */

void uart_tx(uint8_t data) {
    /* Wait for empty transmit buffer */
    while (!(UCSR0A & (1 << UDRE0)));
    UDR0 = data;
}

void uart_puts(const char *str) {
    while (*str) {
        uart_tx(*str++);
    }
}

void uart_puthex8(uint8_t val) {
    const char hex_chars[] = "0123456789ABCDEF";
    uart_tx(hex_chars[(val >> 4) & 0xF]);
    uart_tx(hex_chars[val & 0xF]);
}

void uart_puthex16(uint16_t val) {
    uart_puthex8((uint8_t)(val >> 8));
    uart_puthex8((uint8_t)(val & 0xFF));
}

void uart_putdec8(uint8_t val) {
    uint8_t hundreds = val / 100;
    uint8_t tens = (val % 100) / 10;
    uint8_t ones = val % 10;

    if (hundreds > 0) uart_tx('0' + hundreds);
    if (tens > 0 || hundreds > 0) uart_tx('0' + tens);
    uart_tx('0' + ones);
}

/* ============================================================================
 * Receive Functions
 * ============================================================================ */

uint8_t uart_rx(void) {
    /* Wait for data to be received */
    while (!(UCSR0A & (1 << RXC0)));
    return UDR0;
}

uint8_t uart_rx_available(void) {
    return (UCSR0A & (1 << RXC0)) ? 1 : 0;
}

uint8_t uart_rx_nonblock(uint8_t *data) {
    if (UCSR0A & (1 << RXC0)) {
        *data = UDR0;
        return 1;
    }
    return 0;
}

/* ============================================================================
 * Status Functions
 * ============================================================================ */

void uart_flush_tx(void) {
    /* Wait for transmit complete flag */
    while (!(UCSR0A & (1 << TXC0)));
}

uint8_t uart_get_status(void) {
    return UCSR0A;
}
