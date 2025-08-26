#include "system_ch32v20x.h"
#include "core_riscv.h"
#include "ch32v20x.h"



void clock_config(void) {
    // Set the system clock to 72 MHz
    RCC_TypeDef *clockConfig = RCC_BASE;
    clockConfig->CR |= RCC_HSION; // Enable HSE
    while (!(RCC->CR & RCC_CR_HSERDY)); // Wait for HSE to be ready
    RCC->CFGR |= RCC_CFGR_HPRE_DIV1; // Set AHB prescaler to 1
    RCC->CFGR |= RCC_CFGR_PPRE1_DIV2; // Set APB1 prescaler to 2
}