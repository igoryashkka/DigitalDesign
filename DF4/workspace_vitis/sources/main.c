
#include <stdio.h>
#include "xil_printf.h"
#include "xgpio.h"
#include "xstatus.h"

#define BASEADDR_GPIO_REG_DATA 0x40010000
#define REG1_CHANNEL 1
#define DATA_MASK 0xFF
XGpio gpio_op_sel;

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
    Gpio_init(&gpio_op_sel, XPAR_XGPIO_0_BASEADDR);
    

    while (1) {
        write_to_gpio(&gpio_op_sel, REG1_CHANNEL, 0x1, DATA_MASK); 
        write_to_gpio(&gpio_op_sel, REG1_CHANNEL, 0x0, DATA_MASK); 
    }
}