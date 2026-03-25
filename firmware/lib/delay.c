/* ============================================================================
 * SparkMCU - Delay Library
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Delay functions using CPU cycles
 * ============================================================================ */

#include <stdint.h>
#include <avr/delay.h>

#ifndef F_CPU
#define F_CPU   16000000UL
#endif

/* ============================================================================
 * Delay Functions
 * ============================================================================ */

void delay_cycles(uint32_t cycles) {
    /* Each NOP takes 1 cycle */
    while (cycles--) {
        __asm__ __volatile__("nop");
    }
}

void delay_us(uint32_t microseconds) {
    /* At 16MHz: 16 cycles per microsecond */
    uint32_t cycles = microseconds * (F_CPU / 1000000UL) / 4;  /* Approx, conservative */
    while (cycles--) {
        __asm__ __volatile__("nop");
    }
}

void delay_ms(uint32_t milliseconds) {
    while (milliseconds--) {
        delay_us(1000);
    }
}

void delay_s(uint8_t seconds) {
    while (seconds--) {
        delay_ms(1000);
    }
}

/* ============================================================================
 * Busy-wait Delay (for timing-critical code)
 * ============================================================================ */

void delay_10cycles(void) {
    __asm__ __volatile__(
        "ldi r16, 2\n\t"
        "loop: dec r16\n\t"
        "brne loop\n\t"
        ::: "r16"
    );
}
