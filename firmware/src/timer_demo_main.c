/* ============================================================================
 * SparkMCU - Timer Demo with UART Example
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Demonstrates PWM and CTC mode with UART status output
 * ============================================================================ */

#include <avr/io.h>
#include <stdint.h>

extern void gpio_init(void);
extern void uart_init(void);
extern void uart_puts(const char *str);
extern void uart_puthex8(uint8_t val);
extern void delay_ms(uint32_t milliseconds);
extern void timer0_init_pwm_fast(uint8_t prescaler);
extern void timer0_set_ocra(uint8_t value);
extern void timer0_set_ocrb(uint8_t value);

int main(void) {
    uint8_t pwm_level = 0;
    uint8_t direction = 1;

    gpio_init();
    uart_init();

    /* Print welcome message */
    uart_puts("\r\n========================================\r\n");
    uart_puts("  SparkMCU - Timer PWM Demo\r\n");
    uart_puts("========================================\r\n");
    uart_puts("Generating 16kHz PWM on OC0A/OC0B\r\n");
    uart_puts("PWM Level: ");

    /* Initialize Timer 0 in Fast PWM mode with prescale 1 (16MHz PWM) */
    timer0_init_pwm_fast(1);

    /* Main loop: sweep PWM duty cycle and display via UART */
    while (1) {
        /* Set PWM levels */
        timer0_set_ocra(pwm_level);
        timer0_set_ocrb(255 - pwm_level);

        /* Print PWM level every 256ms */
        uart_puthex8(pwm_level);
        uart_puts("  ");

        /* Sweep PWM from 0-255 then back */
        if (direction) {
            pwm_level++;
            if (pwm_level >= 255) {
                direction = 0;
            }
        } else {
            pwm_level--;
            if (pwm_level == 0) {
                direction = 1;
            }
        }

        delay_ms(256);
    }

    return 0;
}
