; ============================================================================
; SparkMCU - Startup Code (Assembly)
; ============================================================================
; Target: ATmega328P ISA Compatible
; Description: Initializes stack, calls main(), handles reset/interrupts
; ============================================================================

.include "m328pdef.inc"

.global main
.global __vectors

; ============================================================================
; Interrupt Vector Table (0x0000 - 0x003F)
; ============================================================================
.section .vectors

__vectors:
    jmp     __reset         ; 0x00: RESET
    jmp     __bad_interrupt ; 0x02: INT0
    jmp     __bad_interrupt ; 0x04: INT1
    jmp     __bad_interrupt ; 0x06: PCINT0
    jmp     __bad_interrupt ; 0x08: PCINT1
    jmp     __bad_interrupt ; 0x0A: PCINT2
    jmp     __bad_interrupt ; 0x0C: WDT
    jmp     __bad_interrupt ; 0x0E: TIMER2_COMPA
    jmp     __bad_interrupt ; 0x10: TIMER2_COMPB
    jmp     __bad_interrupt ; 0x12: TIMER2_OVF
    jmp     __bad_interrupt ; 0x14: TIMER1_CAPT
    jmp     __bad_interrupt ; 0x16: TIMER1_COMPA
    jmp     __bad_interrupt ; 0x18: TIMER1_COMPB
    jmp     __bad_interrupt ; 0x1A: TIMER1_OVF
    jmp     __bad_interrupt ; 0x1C: TIMER0_COMPA
    jmp     __bad_interrupt ; 0x1E: TIMER0_COMPB
    jmp     __bad_interrupt ; 0x20: TIMER0_OVF
    jmp     __bad_interrupt ; 0x22: SPI_STC
    jmp     __bad_interrupt ; 0x24: UART_RXC
    jmp     __bad_interrupt ; 0x26: UART_UDRE
    jmp     __bad_interrupt ; 0x28: UART_TXC
    jmp     __bad_interrupt ; 0x2A: ADC
    jmp     __bad_interrupt ; 0x2C: EE_RDY
    jmp     __bad_interrupt ; 0x2E: ANALOG_COMP
    jmp     __bad_interrupt ; 0x30: TWI
    jmp     __bad_interrupt ; 0x32: SPM_RDY

; ============================================================================
; Reset Handler
; ============================================================================
.section .text

__reset:
    ; Initialize stack pointer to end of SRAM
    ldi     r16, lo8(RAMEND)
    out     SPL, r16
    ldi     r16, hi8(RAMEND)
    out     SPH, r16

    ; Clear BSS section (if needed by linker)
    ; Call global constructors (C++)
    ; Enable global interrupts (optional)
    ; sei

    ; Call main()
    call    main

    ; If main returns, loop forever
__main_exit:
    rjmp    __main_exit

; ============================================================================
; Catch-all interrupt handler
; ============================================================================
__bad_interrupt:
    reti

; ============================================================================
; End of Startup Code
; ============================================================================
