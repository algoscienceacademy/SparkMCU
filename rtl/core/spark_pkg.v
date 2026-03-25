// ============================================================================
// SparkMCU - AVR-Compatible 8-bit Microcontroller
// SkyWater 130nm / OpenLane Target
// ============================================================================
// Package: Global parameters and definitions
// ============================================================================
// Architecture: Modified Harvard (separate program & data memory buses)
// ISA: AVR (ATmega328P compatible subset)
// ============================================================================

// ---------------------------------------------------------------------------
// ALU Operation Codes
// ---------------------------------------------------------------------------
`define ALU_OP_ADD    4'b0000
`define ALU_OP_ADC    4'b0001
`define ALU_OP_SUB    4'b0010
`define ALU_OP_SBC    4'b0011
`define ALU_OP_AND    4'b0100
`define ALU_OP_OR     4'b0101
`define ALU_OP_EOR    4'b0110
`define ALU_OP_COM    4'b0111
`define ALU_OP_NEG    4'b1000
`define ALU_OP_INC    4'b1001
`define ALU_OP_DEC    4'b1010
`define ALU_OP_LSR    4'b1011
`define ALU_OP_ROR    4'b1100
`define ALU_OP_ASR    4'b1101
`define ALU_OP_SWAP   4'b1110
`define ALU_OP_MUL    4'b1111

// ---------------------------------------------------------------------------
// SREG Bit Positions
// ---------------------------------------------------------------------------
`define SREG_C  0   // Carry
`define SREG_Z  1   // Zero
`define SREG_N  2   // Negative
`define SREG_V  3   // Overflow
`define SREG_S  4   // Sign (N xor V)
`define SREG_H  5   // Half Carry
`define SREG_T  6   // Bit Copy
`define SREG_I  7   // Global Interrupt Enable

// ---------------------------------------------------------------------------
// Memory Map (ATmega328P compatible)
// ---------------------------------------------------------------------------
`define REG_FILE_BASE   16'h0000   // R0-R31:  0x0000 - 0x001F
`define IO_REG_BASE     16'h0020   // I/O:     0x0020 - 0x005F
`define EXT_IO_BASE     16'h0060   // Ext I/O: 0x0060 - 0x00FF
`define SRAM_BASE       16'h0100   // SRAM:    0x0100 - 0x08FF (2KB)
`define SRAM_SIZE       2048
`define FLASH_SIZE      32768      // 32KB (16K words)

// ---------------------------------------------------------------------------
// I/O Register Addresses (offset from IO_REG_BASE)
// ---------------------------------------------------------------------------
`define IO_PINB     6'h03
`define IO_DDRB     6'h04
`define IO_PORTB    6'h05
`define IO_PINC     6'h06
`define IO_DDRC     6'h07
`define IO_PORTC    6'h08
`define IO_PIND     6'h09
`define IO_DDRD     6'h0A
`define IO_PORTD    6'h0B

`define IO_TIFR0    6'h15
`define IO_TIFR1    6'h16
`define IO_TIFR2    6'h17

`define IO_PCIFR    6'h1B
`define IO_EIFR     6'h1C
`define IO_EIMSK    6'h1D

`define IO_GPIOR0   6'h1E

`define IO_TCCR0A   6'h24
`define IO_TCCR0B   6'h25
`define IO_TCNT0    6'h26
`define IO_OCR0A    6'h27
`define IO_OCR0B    6'h28

`define IO_SPCR     6'h2C
`define IO_SPSR     6'h2D
`define IO_SPDR     6'h2E

`define IO_SREG     6'h3F
`define IO_SPH      6'h3E
`define IO_SPL      6'h3D

// ---------------------------------------------------------------------------
// Extended I/O (offset from 0x0060)
// ---------------------------------------------------------------------------
`define EIO_UDR0    8'h86    // Absolute 0xC6
`define EIO_UBRR0L  8'h84   // Absolute 0xC4
`define EIO_UBRR0H  8'h85   // Absolute 0xC5
`define EIO_UCSR0C  8'h82   // Absolute 0xC2
`define EIO_UCSR0B  8'h81   // Absolute 0xC1
`define EIO_UCSR0A  8'h80   // Absolute 0xC0

`define EIO_TIMSK0  8'h6E   // Absolute 0x6E
`define EIO_TIMSK1  8'h6F   // Absolute 0x6F
`define EIO_TIMSK2  8'h70   // Absolute 0x70

// ---------------------------------------------------------------------------
// Interrupt Vector Numbers
// ---------------------------------------------------------------------------
`define INT_RESET   5'd0
`define INT_INT0    5'd1
`define INT_INT1    5'd2
`define INT_PCINT0  5'd3
`define INT_PCINT1  5'd4
`define INT_PCINT2  5'd5
`define INT_WDT     5'd6
`define INT_TIMER2_COMPA 5'd7
`define INT_TIMER2_COMPB 5'd8
`define INT_TIMER2_OVF   5'd9
`define INT_TIMER1_CAPT  5'd10
`define INT_TIMER1_COMPA 5'd11
`define INT_TIMER1_COMPB 5'd12
`define INT_TIMER1_OVF   5'd13
`define INT_TIMER0_COMPA 5'd14
`define INT_TIMER0_COMPB 5'd15
`define INT_TIMER0_OVF   5'd16
`define INT_SPI_STC      5'd17
`define INT_USART_RXC    5'd18
`define INT_USART_UDRE   5'd19
`define INT_USART_TXC    5'd20

// ---------------------------------------------------------------------------
// CPU States
// ---------------------------------------------------------------------------
`define CPU_STATE_FETCH    3'b000
`define CPU_STATE_DECODE   3'b001
`define CPU_STATE_EXECUTE  3'b010
`define CPU_STATE_MEMORY   3'b011
`define CPU_STATE_WRITEBACK 3'b100
`define CPU_STATE_STALL    3'b101
`define CPU_STATE_IRQ      3'b110
