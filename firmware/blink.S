; ============================================================================
; SparkMCU - Sample AVR Assembly: LED Blink
; ============================================================================
; Target: SparkMCU (ATmega328P compatible)
; Description: Blinks all LEDs on Port B with a delay loop
;
; To assemble: avr-as -mmcu=atmega328p -o blink.o blink.S
; To link:     avr-ld -o blink.elf blink.o
; To hex:      avr-objcopy -O ihex blink.elf blink.hex
; ============================================================================

.include "m328pdef.inc"

.org 0x0000
    rjmp    RESET           ; Reset vector

.org 0x0034                 ; Past all interrupt vectors
RESET:
    ; Initialize stack pointer
    ldi     r16, lo8(RAMEND)
    out     SPL, r16
    ldi     r16, hi8(RAMEND)
    out     SPH, r16

    ; Set Port B as output
    ldi     r16, 0xFF
    out     DDRB, r16

    ; Clear Port B
    ldi     r16, 0x00
    out     PORTB, r16

MAIN_LOOP:
    ; Turn ON all LEDs
    ldi     r16, 0xFF
    out     PORTB, r16
    rcall   DELAY

    ; Turn OFF all LEDs
    ldi     r16, 0x00
    out     PORTB, r16
    rcall   DELAY

    rjmp    MAIN_LOOP

; -----------------------------------------------------------------------
; Delay subroutine (~0.5s at 16 MHz)
; -----------------------------------------------------------------------
DELAY:
    ldi     r18, 0x14       ; Outer loop count
DELAY_L1:
    ldi     r19, 0xFF       ; Middle loop count
DELAY_L2:
    ldi     r20, 0xFF       ; Inner loop count
DELAY_L3:
    dec     r20
    brne    DELAY_L3
    dec     r19
    brne    DELAY_L2
    dec     r18
    brne    DELAY_L1
    ret
