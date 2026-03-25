/* ============================================================================
 * SparkMCU Device Header - ATmega328P Register Definitions
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Device memory map and register definitions
 * ============================================================================ */

#ifndef __SPARK_MCU_H__
#define __SPARK_MCU_H__

#include <stdint.h>
#include <avr/io.h>

/* ============================================================================
 * Memory Addresses
 * ============================================================================ */

#define FLASH_BASE      0x0000      /* Program Memory - 32KB */
#define FLASH_SIZE      0x8000
#define SRAM_BASE       0x0060      /* Internal SRAM - 256 bytes */
#define SRAM_SIZE       0x0100
#define SRAM_EXT_BASE   0x0100      /* Extended SRAM - 2KB */
#define SRAM_EXT_SIZE   0x0800
#define EEPROM_BASE     0x0000      /* EEPROM - 1KB */
#define EEPROM_SIZE     0x0400

/* ============================================================================
 * Port Addresses (I/O Space)
 * ============================================================================ */

/* Port B (8-bit GPIO) */
#define PORTB_BASE      0x25
#define DDRB_BASE       0x24
#define PINB_BASE       0x23

/* Port C (6-bit GPIO) */
#define PORTC_BASE      0x28
#define DDRC_BASE       0x27
#define PINC_BASE       0x26

/* Port D (8-bit GPIO) */
#define PORTD_BASE      0x2B
#define DDRD_BASE       0x2A
#define PIND_BASE       0x29

/* ============================================================================
 * UART Registers (USART0)
 * ============================================================================ */

#define UBRR0H_BASE     0xA1
#define UBRR0L_BASE     0xA0
#define UCSR0A_BASE     0x9F
#define UCSR0B_BASE     0x9E
#define UCSR0C_BASE     0x9D
#define UDR0_BASE       0x9C

/* UCSR0A Bits */
#define RXC0    7       /* Receive Complete */
#define TXC0    6       /* Transmit Complete */
#define UDRE0   5       /* Data Register Empty */
#define FE0     4       /* Frame Error */
#define DOR0    3       /* Data Overrun */
#define PE0     2       /* Parity Error */
#define U2X0    1       /* Double Transmission Speed */
#define MPCM0   0       /* Multi-Processor Communication Mode */

/* UCSR0B Bits */
#define RXCIE0  7       /* Receive Complete Interrupt Enable */
#define TXCIE0  6       /* Transmit Complete Interrupt Enable */
#define UDRIE0  5       /* Data Register Empty Interrupt Enable */
#define RXEN0   4       /* Receiver Enable */
#define TXEN0   3       /* Transmitter Enable */
#define UCSZ02  2       /* Character Size (bit 2) */
#define RXB80   1       /* Receive Data Bit 8 */
#define TXB80   0       /* Transmit Data Bit 8 */

/* UCSR0C Bits */
#define UMSEL01 7       /* USART Mode Select (bit 1) */
#define UMSEL00 6       /* USART Mode Select (bit 0) */
#define UPM01   5       /* Parity Mode (bit 1) */
#define UPM00   4       /* Parity Mode (bit 0) */
#define USBS0   3       /* Stop Bit Select */
#define UCSZ01  2       /* Character Size (bit 1) */
#define UCSZ00  1       /* Character Size (bit 0) */
#define UCPOL0  0       /* Clock Polarity */

/* ============================================================================
 * SPI Registers
 * ============================================================================ */

#define SPCR_BASE       0x4C
#define SPSR_BASE       0x4D
#define SPDR_BASE       0x4E

/* SPCR Bits */
#define SPIE    7       /* SPI Interrupt Enable */
#define SPE     6       /* SPI Enable */
#define DORD    5       /* Data Order */
#define MSTR    4       /* Master/Slave Select */
#define CPOL    3       /* Clock Polarity */
#define CPHA    2       /* Clock Phase */
#define SPR1    1       /* SPI Clock Rate Select (bit 1) */
#define SPR0    0       /* SPI Clock Rate Select (bit 0) */

/* SPSR Bits */
#define SPIF    7       /* SPI Interrupt Flag */
#define WCOL    6       /* Write Collision Flag */
#define SPI2X   0       /* Double SPI Speed */

/* ============================================================================
 * Timer/Counter 0 Registers
 * ============================================================================ */

#define TCCR0A_BASE     0x44
#define TCCR0B_BASE     0x45
#define TCNT0_BASE      0x46
#define OCR0A_BASE      0x47
#define OCR0B_BASE      0x48
#define TIMSK0_BASE     0x6E
#define TIFR0_BASE      0x35

/* TCCR0A Bits */
#define COM0A1  7
#define COM0A0  6
#define COM0B1  5
#define COM0B0  4
#define WGM01   1
#define WGM00   0

/* TCCR0B Bits */
#define FOC0A   7
#define FOC0B   6
#define WGM02   3
#define CS02    2
#define CS01    1
#define CS00    0

/* TIMSK0 Bits */
#define OCIE0B  2       /* Output Compare B Match Interrupt Enable */
#define OCIE0A  1       /* Output Compare A Match Interrupt Enable */
#define TOIE0   0       /* Overflow Interrupt Enable */

/* TIFR0 Bits */
#define OCF0B   2       /* Output Compare B Match Flag */
#define OCF0A   1       /* Output Compare A Match Flag */
#define TOV0    0       /* Overflow Flag */

/* ============================================================================
 * Interrupt Control Register
 * ============================================================================ */

#define EICRA_BASE      0x69
#define EIMSK_BASE      0x3D
#define EIFR_BASE       0x3C
#define PCICR_BASE      0x68
#define PCIFR_BASE      0x3B

/* EICRA Bits */
#define ISC11   3       /* INT1 Sense Control (bit 1) */
#define ISC10   2       /* INT1 Sense Control (bit 0) */
#define ISC01   1       /* INT0 Sense Control (bit 1) */
#define ISC00   0       /* INT0 Sense Control (bit 0) */

/* ============================================================================
 * Status Register
 * ============================================================================ */

#define SREG_BASE       0x3F

/* SREG Bits */
#define I       7       /* Global Interrupt Enable */
#define T       6       /* Bit Copy Storage */
#define H       5       /* Half-Carry Flag */
#define S       4       /* Sign Bit */
#define V       3       /* Two's Complement Overflow Flag */
#define N       2       /* Negative Flag */
#define Z       1       /* Zero Flag */
#define C       0       /* Carry Flag */

/* ============================================================================
 * Macros for Common Operations
 * ============================================================================ */

#define ENABLE_INTERRUPTS()     __asm__ __volatile__ ("sei" ::: "memory")
#define DISABLE_INTERRUPTS()    __asm__ __volatile__ ("cli" ::: "memory")

#endif /* __SPARK_MCU_H__ */
