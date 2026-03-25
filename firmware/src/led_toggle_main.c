/* ============================================================================
 * SparkMCU - LED Toggle with Timer Example
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Toggles LEDs using Timer/Counter 0 in CTC mode
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

extern void gpio_init(void);
extern void timer0_init_ctc(uint8_t prescaler, uint8_t compare_value);
extern void timer0_enable_compa_int(void);

volatile uint8_t toggle_count = 0;

/* Timer 0 Compare A ISR */
ISR(TIMER0_COMPA_vect) {
    toggle_count++;
    
    /* Toggle LED every 50 interrupts (~0.5s at 16MHz, prescale 1024, OCR=125) */
    if (toggle_count >= 50) {
        PORTB ^= 0xFF;      /* Toggle all LEDs */
        toggle_count = 0;
    }
}

int main(void) {
    gpio_init();

    /* Initialize Timer 0 in CTC mode */
    /* Prescale 1024, Compare = 125 */
    /* Interrupt period = (125 + 1) * 1024 / 16MHz ≈ 8ms */
    timer0_init_ctc(5, 125);        /* 5 = prescale 1024 */
    timer0_enable_compa_int();

    /* Enable global interrupts */
    sei();

    /* Main loop - CPU can do other tasks */
    while (1) {
        /* Could do other work here */
    }

    return 0;
}
