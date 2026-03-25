/* ============================================================================
 * SparkMCU - GPIO Library
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: GPIO initialization and control functions
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

/* ============================================================================
 * GPIO Port Initialization
 * ============================================================================ */

void gpio_init(void) {
    /* Port B: All outputs (LEDs/debug) */
    DDRB = 0xFF;
    PORTB = 0x00;

    /* Port C: All outputs (debug) */
    DDRC = 0xFF;
    PORTC = 0x00;

    /* Port D: PD0 (RXD) input, PD1 (TXD) output, rest outputs */
    DDRD = 0xFE;        /* PD0 as input, others as output */
    PORTD = 0x00;
}

/* ============================================================================
 * Individual Port Configuration
 * ============================================================================ */

void gpio_set_ddr(volatile uint8_t *ddr, uint8_t pin, uint8_t dir) {
    if (dir) {
        *ddr |= (1 << pin);     /* Output */
    } else {
        *ddr &= ~(1 << pin);    /* Input */
    }
}

void gpio_set_port(volatile uint8_t *port, uint8_t pin, uint8_t value) {
    if (value) {
        *port |= (1 << pin);    /* Set high */
    } else {
        *port &= ~(1 << pin);   /* Set low */
    }
}

uint8_t gpio_read_pin(volatile uint8_t *pin, uint8_t bit) {
    return (*pin >> bit) & 1;
}

/* ============================================================================
 * Port B Convenience Functions
 * ============================================================================ */

void portb_set(uint8_t value) {
    PORTB = value;
}

void portb_set_bit(uint8_t bit) {
    PORTB |= (1 << bit);
}

void portb_clr_bit(uint8_t bit) {
    PORTB &= ~(1 << bit);
}

void portb_toggle_bit(uint8_t bit) {
    PORTB ^= (1 << bit);
}

uint8_t portb_read(void) {
    return PINB;
}

/* ============================================================================
 * Port D Convenience Functions (for UART pins)
 * ============================================================================ */

void portd_set(uint8_t value) {
    PORTD = value;
}

void portd_set_bit(uint8_t bit) {
    PORTD |= (1 << bit);
}

void portd_clr_bit(uint8_t bit) {
    PORTD &= ~(1 << bit);
}

uint8_t portd_read(void) {
    return PIND;
}
