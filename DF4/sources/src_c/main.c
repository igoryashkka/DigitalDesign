
#include <stdio.h>
#include "xil_printf.h"
#include "xgpio.h"
#include "xstatus.h"

#define REG1_CHANNEL 1
#define DATA_MASK 0xFF
XGpio gpio_h;

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
         write_to_gpio(&gpio_h, REG1_CHANNEL, 130U, DATA_MASK); 


    while (1) {
        //write_to_gpio(&gpio_h, REG1_CHANNEL, 0x1, DATA_MASK); 
        //write_to_gpio(&gpio_h, REG1_CHANNEL, 0x0, DATA_MASK); 
    }
}