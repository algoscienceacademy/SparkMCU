/* ============================================================================
 * SparkMCU - LED Blink Example
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Simple LED blink using Port B (PB0-PB7)
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

extern void gpio_init(void);
extern void delay_ms(uint32_t milliseconds);

int main(void) {
    gpio_init();

    while (1) {
        /* Turn on all LEDs on Port B */
        PORTB = 0xFF;
        delay_ms(500);

        /* Turn off all LEDs on Port B */
        PORTB = 0x00;
        delay_ms(500);
    }

    return 0;
}
