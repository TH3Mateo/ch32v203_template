
// #include "ch32v20x_misc.h"
#include "system_ch32v20x.h"
#include "core_riscv.h"
#include "debug.h"
#include "ch32v20x_rcc.h"

#include "ch32v20x_gpio.h"
// #include "FreeRTOSConfig.h"
// #include "FreeRTOS.h"

#define SYSCLK_FREQ_48MHz_HSI 1

// void blink_task(void *params) {
//     while (1) {
//         GPIO_WriteBit(GPIOA, GPIO_Pin_0, Bit_SET);  // Set PA0 high
//         // vTaskDelay(pdMS_TO_TICKS(500));
//     }
// }

int main() {


    SystemInit();
    SystemCoreClockUpdate();
    Delay_Init();
    

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
    GPIO_InitTypeDef gpio = { GPIO_Pin_2, GPIO_Speed_50MHz, GPIO_Mode_Out_OD };
    GPIO_Init(GPIOA, &gpio);
    // xTaskCreate(blink_task, "LED", 128, NULL, 1, NULL);


    while (1)
    {
        GPIO_WriteBit(GPIOA, GPIO_Pin_2, Bit_SET);
        Delay_Ms(500);
        GPIO_WriteBit(GPIOA, GPIO_Pin_2, Bit_RESET);
        Delay_Ms(500);
    }
    return 0;
}


