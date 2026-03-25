/* ============================================================================
 * SparkMCU - UART Echo Example
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Echo received UART characters back to sender
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

extern void gpio_init(void);
extern void uart_init(void);
extern void uart_tx(uint8_t data);
extern uint8_t uart_rx(void);
extern void uart_puts(const char *str);

int main(void) {
    uint8_t rx_byte;

    gpio_init();
    uart_init();

    /* Send welcome message */
    uart_puts("\r\n========================================\r\n");
    uart_puts("  SparkMCU - UART Echo\r\n");
    uart_puts("  16 MHz AVR-Compatible Microcontroller\r\n");
    uart_puts("========================================\r\n");
    uart_puts("Type something...\r\n\r\n");

    /* Main loop: echo received characters */
    while (1) {
        rx_byte = uart_rx();

        /* Echo back the character */
        uart_tx(rx_byte);

        /* Show received byte on LEDs (Port B) */
        PORTB = rx_byte;

        /* If Enter is pressed, send new line */
        if (rx_byte == '\r') {
            uart_tx('\n');
        }
    }

    return 0;
}
