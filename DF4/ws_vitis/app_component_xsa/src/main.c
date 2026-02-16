
#include <stdio.h>
#include "xil_printf.h"
#include "xgpio.h"
#include "xstatus.h"
#include "sleep.h"


#define REG1_CHANNEL 1

#define DATA_MASK 0xFF
XGpio gpio_h;
XGpio gpio_h1;

#define TOP_BASE      XPAR_TOP_GPIO_0_BASEADDR   // 0x00010000
#define TOP_REG_OFF   0x00                       
#define TOP_MASK      0xFF

static inline void top_write_u8(u32 v)
{
    Xil_Out32(TOP_BASE + TOP_REG_OFF, v & TOP_MASK);
}

static inline u32 top_read_u32(void)
{
    return Xil_In32(TOP_BASE + TOP_REG_OFF);
}

void write_to_gpio(XGpio *confPtr, char channel, char data, char dataMask)
{
    char data_masked = data & dataMask;
    XGpio_DiscreteWrite(confPtr, channel, data_masked);
}

void Gpio_init(XGpio *confPtr, int base_addr)
{
    XGpio_Initialize(confPtr, base_addr);
}

int main(void)
{
    Gpio_init(&gpio_h, XPAR_XGPIO_0_BASEADDR);
    Gpio_init(&gpio_h1, XPAR_TOP_GPIO_0_BASEADDR);

    while (1) {
        write_to_gpio(&gpio_h, REG1_CHANNEL, 20U, DATA_MASK);
        top_write_u8(200);
        usleep(500000);   // 500 мс

        write_to_gpio(&gpio_h, REG1_CHANNEL, 200U, DATA_MASK);
         top_write_u8(20);
        usleep(500000);   // 500 мс
        
    }
}