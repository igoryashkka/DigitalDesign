#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "sleep.h"


#define BTN_INC_A    (1U << 0)
#define BTN_DEC_A    (1U << 1)
#define BTN_INC_B    (1U << 2)
#define BTN_DEC_B    (1U << 3)
#define BTN_OP_STEP  (1U << 4)
#define BTN_MODE_STEP (1U << 5)
#define BTN_MASK     (BTN_INC_A|BTN_DEC_A|BTN_INC_B|BTN_DEC_B|BTN_OP_STEP|BTN_MODE_STEP)

#define CH 1  

static inline void gpio_write_masked(XGpio* g, u32 value)
{
    XGpio_DiscreteWrite(g, CH, (value & BTN_MASK));
}

static inline void press_level(XGpio* g, u32 bitmask, uint32_t hold_us)
{
    gpio_write_masked(g, bitmask);
    usleep(hold_us);
    gpio_write_masked(g, 0);
    usleep(hold_us);
}

int main(void)
{
 
    XGpio Gpio;
    XGpio_Config* Cfg = XGpio_LookupConfig(0);
  
    if (XGpio_CfgInitialize(&Gpio, Cfg, Cfg->BaseAddress) != XST_SUCCESS){/*while(1);*/}


    XGpio_SetDataDirection(&Gpio, CH, 0x00000000U);
    gpio_write_masked(&Gpio, 0);


    const uint32_t T = 1000; 

     press_level(&Gpio, BTN_INC_A, T);
     press_level(&Gpio, BTN_INC_A, T);
     press_level(&Gpio, BTN_INC_A, T);
     press_level(&Gpio, BTN_INC_A, T);
     press_level(&Gpio, BTN_INC_A, T);
     press_level(&Gpio, BTN_INC_A, T);

    while (1) {
        press_level(&Gpio, BTN_INC_A, T);
       // press_level(&Gpio, BTN_MODE_STEP, T);
        usleep(500 * T);
    }
}
