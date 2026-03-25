/* ==========================================================================
 * SparkMCU - Sample C Firmware: UART Echo
 * ==========================================================================
 * Target: SparkMCU (ATmega328P compatible)
 * Description: Echoes received UART characters back to sender
 *
 * To compile: avr-gcc -mmcu=atmega328p -Os -o uart_echo.elf uart_echo.c
 * To hex:     avr-objcopy -O ihex uart_echo.elf uart_echo.hex
 * ========================================================================== */

#include <avr/io.h>
#include <avr/interrupt.h>

#define F_CPU   16000000UL
#define BAUD    9600
#define UBRR_VAL ((F_CPU / 16 / BAUD) - 1)

/* Initialize UART at 9600 baud, 8N1 */
void uart_init(void) {
    /* Set baud rate */
    UBRR0H = (uint8_t)(UBRR_VAL >> 8);
    UBRR0L = (uint8_t)(UBRR_VAL);

    /* Enable receiver and transmitter */
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);

    /* Set frame format: 8 data bits, 1 stop bit, no parity */
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

/* Transmit a single byte */
void uart_tx(uint8_t data) {
    /* Wait for empty transmit buffer */
    while (!(UCSR0A & (1 << UDRE0)));
    UDR0 = data;
}

/* Receive a single byte (blocking) */
uint8_t uart_rx(void) {
    /* Wait for data to be received */
    while (!(UCSR0A & (1 << RXC0)));
    return UDR0;
}

/* Send a null-terminated string */
void uart_puts(const char *str) {
    while (*str) {
        uart_tx(*str++);
    }
}

/* Initialize GPIO */
void gpio_init(void) {
    /* Port B: all outputs (LEDs) */
    DDRB = 0xFF;
    PORTB = 0x00;

    /* Port D: PD0 (RXD) input, PD1 (TXD) output */
    DDRD = 0x02;
}

int main(void) {
    uint8_t rx_byte;

    gpio_init();
    uart_init();

    /* Send welcome message */
    uart_puts("SparkMCU AVR Clone - UART Echo\r\n");
    uart_puts("Type something...\r\n");

    /* Main loop: echo received characters */
    while (1) {
        rx_byte = uart_rx();

        /* Echo back */
        uart_tx(rx_byte);

        /* Show received byte on LEDs */
        PORTB = rx_byte;
    }

    return 0;
}
