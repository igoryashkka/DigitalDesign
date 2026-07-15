#include <stdio.h>
#include "xil_printf.h"
#include "xgpio.h"
#include "xstatus.h"
#include "sleep.h"
#include "xil_io.h"
#include "xil_types.h"


#define REG1_CHANNEL      1
#define GPIO_MASK_8BIT    0xFFu

#define DELAY_US          500000u   // 500 ms

#define TOP_BASE          XPAR_TOP_GPIO_0_BASEADDR
#define TOP_REG_OFF       0x00u
#define TOP_MASK_8BIT     0xFFu

static XGpio g_gpio_std;   
static XGpio g_gpio_top;   

// ------------------------------------------------------------
// Custom AXI GPIO 
static inline void top_write_u8(u8 v)
{
    Xil_Out32(TOP_BASE + TOP_REG_OFF, (u32)(v & TOP_MASK_8BIT));
}

static inline u32 top_read_u32(void)
{
    return Xil_In32(TOP_BASE + TOP_REG_OFF);
}
// ------------------------------------------------------------
// Standard AXI GPIO
static int gpio_init(XGpio *inst, u32 device_id_or_baseaddr)
{
    return XGpio_Initialize(inst, device_id_or_baseaddr);
}

static inline void gpio_write_u8(XGpio *inst, u32 channel, u8 value)
{
    XGpio_DiscreteWrite(inst, channel, (u32)value);
}
// ------------------------------------------------------------
// Common function to set duty pwm
static void set_duty_pwm(u8 duty_std, u8 duty_top)
{
    gpio_write_u8(&g_gpio_std, REG1_CHANNEL, (u8)(duty_std & GPIO_MASK_8BIT));
    top_write_u8((u8)(duty_top & TOP_MASK_8BIT));
}
// ------------------------------------------------------------
int main(void)
{
    int status;

    status = gpio_init(&g_gpio_std, XPAR_XGPIO_0_BASEADDR);
    status = gpio_init(&g_gpio_top, XPAR_TOP_GPIO_0_BASEADDR);


    while (1) {
        set_duty_pwm(20u, 200u);
        usleep(DELAY_US);

        set_duty_pwm(200u, 20u);
        usleep(DELAY_US);
    }
}
