/* ============================================================================
 * SparkMCU - Linker Script
 * ============================================================================
 * Target: ATmega328P ISA Compatible
 * Description: Memory layout for AVR microcontroller
 * ============================================================================
 *
 * ATmega328P Memory Map:
 *   0x0000 - 0x7FFF:  Program Memory (Flash) - 32KB
 *   0x0060 - 0x00FF:  Internal SRAM - 256 bytes
 *   0x0100 - 0x08FF:  Extended SRAM - 2KB
 *
 * ============================================================================ */

MEMORY
{
    flash   (rx)   : ORIGIN = 0x000000, LENGTH = 32K
    sram    (rw!x) : ORIGIN = 0x800060, LENGTH = 2K + 160
    eeprom  (rw!x) : ORIGIN = 0x810000, LENGTH = 1K
}

SECTIONS
{
    /* Read-only data and code go to FLASH */
    .text :
    {
        __vectors_start = ABSOLUTE(.);
        *(.vectors*)
        __vectors_end = ABSOLUTE(.);

        *(.text*)
        *(.rodata*)
        *(.init*)
        *(.fini*)
        . = ALIGN(2);
        __data_load_start = ABSOLUTE(.);
    } > flash

    /* Initialized data is placed in FLASH but loaded into SRAM */
    .data : AT (__data_load_start)
    {
        __data_start = ABSOLUTE(.);
        *(.data*)
        . = ALIGN(2);
        __data_end = ABSOLUTE(.);
    } > sram

    /* Uninitialized data goes to SRAM */
    .bss :
    {
        __bss_start = ABSOLUTE(.);
        *(.bss*)
        *(COMMON)
        . = ALIGN(2);
        __bss_end = ABSOLUTE(.);
    } > sram

    /* EEPROM data */
    .eeprom :
    {
        *(.eeprom*)
        . = ALIGN(2);
    } > eeprom

    /* Discard debug and comment sections */
    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
        *(.debug*)
    }

    /* Set end of stack */
    __stack_end = ORIGIN(sram) + LENGTH(sram);
    PROVIDE (__stack_end = __stack_end);

    /* Symbols for C runtime */
    __data_load_size = __data_end - __data_start;
    __bss_size = __bss_end - __bss_start;
}
