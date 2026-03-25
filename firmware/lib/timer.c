/* ============================================================================
 * SparkMCU - Timer Library
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Timer/Counter 0 PWM and interrupt functions
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

/* ============================================================================
 * Timer 0 Initialization
 * ============================================================================ */

void timer0_init_normal(uint8_t prescaler) {
    /* Disable Timer 0 */
    TCCR0B = 0;

    /* Clear counter */
    TCNT0 = 0;

    /* Mode: Normal (WGM02:00 = 000) */
    TCCR0A = 0x00;

    /* Set prescaler and start timer */
    TCCR0B = prescaler & 0x07;
}

void timer0_init_ctc(uint8_t prescaler, uint8_t compare_value) {
    /* Disable Timer 0 */
    TCCR0B = 0;

    /* Clear counter */
    TCNT0 = 0;

    /* Mode: CTC - Clear Timer on Compare (WGM02:00 = 010) */
    TCCR0A = (1 << WGM01);
    TCCR0B = 0;

    /* Set compare value */
    OCR0A = compare_value;

    /* Set prescaler and start timer */
    TCCR0B = prescaler & 0x07;
}

void timer0_init_pwm_fast(uint8_t prescaler) {
    /* Disable Timer 0 */
    TCCR0B = 0;

    /* Clear counter */
    TCNT0 = 0;

    /* Mode: Fast PWM (WGM02:00 = 011), Compare Output Mode A/B = 10 (non-inverted) */
    TCCR0A = (1 << COM0A1) | (1 << COM0B1) | (1 << WGM01) | (1 << WGM00);
    TCCR0B = 0;

    /* Set prescaler and start timer */
    TCCR0B = prescaler & 0x07;
}

void timer0_init_pwm_phase(uint8_t prescaler) {
    /* Disable Timer 0 */
    TCCR0B = 0;

    /* Clear counter */
    TCNT0 = 0;

    /* Mode: Phase Correct PWM (WGM02:00 = 001), Compare Output Mode A/B = 10 (non-inverted) */
    TCCR0A = (1 << COM0A1) | (1 << COM0B1) | (1 << WGM00);
    TCCR0B = 0;

    /* Set prescaler and start timer */
    TCCR0B = prescaler & 0x07;
}

/* ============================================================================
 * Timer Control Functions
 * ============================================================================ */

void timer0_stop(void) {
    TCCR0B &= ~0x07;    /* Clear prescaler bits */
}

void timer0_start(uint8_t prescaler) {
    TCCR0B = (TCCR0B & ~0x07) | (prescaler & 0x07);
}

void timer0_set_count(uint8_t value) {
    TCNT0 = value;
}

uint8_t timer0_get_count(void) {
    return TCNT0;
}

void timer0_set_ocra(uint8_t value) {
    OCR0A = value;
}

void timer0_set_ocrb(uint8_t value) {
    OCR0B = value;
}

/* ============================================================================
 * Timer Interrupt Functions
 * ============================================================================ */

void timer0_enable_overflow_int(void) {
    TIMSK0 |= (1 << TOIE0);
}

void timer0_disable_overflow_int(void) {
    TIMSK0 &= ~(1 << TOIE0);
}

void timer0_enable_compa_int(void) {
    TIMSK0 |= (1 << OCIE0A);
}

void timer0_disable_compa_int(void) {
    TIMSK0 &= ~(1 << OCIE0A);
}

void timer0_enable_compb_int(void) {
    TIMSK0 |= (1 << OCIE0B);
}

void timer0_disable_compb_int(void) {
    TIMSK0 &= ~(1 << OCIE0B);
}

void timer0_clear_overflow_flag(void) {
    TIFR0 |= (1 << TOV0);
}

void timer0_clear_compa_flag(void) {
    TIFR0 |= (1 << OCF0A);
}

void timer0_clear_compb_flag(void) {
    TIFR0 |= (1 << OCF0B);
}

/* ============================================================================
 * Timer Prescaler Constants
 * ============================================================================ */
/* 
 * TIMER0_PRESCALER_OFF    0   - Timer disabled
 * TIMER0_PRESCALER_1      1   - No prescaling
 * TIMER0_PRESCALER_8      2   - Prescale by 8
 * TIMER0_PRESCALER_64     3   - Prescale by 64
 * TIMER0_PRESCALER_256    4   - Prescale by 256
 * TIMER0_PRESCALER_1024   5   - Prescale by 1024
 * TIMER0_EXT_FALL         6   - External clock on falling edge
 * TIMER0_EXT_RISE         7   - External clock on rising edge
 */
