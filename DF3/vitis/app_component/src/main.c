#include "xgpio.h"
#include "xil_printf.h"
#include "sleep.h"
#include <stdint.h>

#define CH1 1U
#define CH2 2U

#define BTN_INC_A     (1U << 0)
#define BTN_DEC_A     (1U << 1)
#define BTN_INC_B     (1U << 2)
#define BTN_DEC_B     (1U << 3)
#define BTN_OP_STEP   (1U << 4)
#define BTN_MODE_STEP (1U << 5)
#define BTN_MASK_CH1  (BTN_INC_A | BTN_DEC_A | BTN_INC_B | BTN_DEC_B | BTN_OP_STEP | BTN_MODE_STEP)
#define BTN_DSP_USE   (1U << 0)
#define BTN_MASK_CH2  (BTN_DSP_USE)

static volatile u32 gpio_state_ch1 = 0U;
static volatile u32 gpio_state_ch2 = 0U;

static inline void gpio_apply(XGpio *g)
{
    XGpio_DiscreteWrite(g, CH1, gpio_state_ch1 & BTN_MASK_CH1);
    XGpio_DiscreteWrite(g, CH2, gpio_state_ch2 & BTN_MASK_CH2);
}

static inline void gpio_set(XGpio *g, u32 ch, u32 set_mask)
{
    if (ch == CH1) {
        gpio_state_ch1 |= (set_mask & BTN_MASK_CH1);
    } else if (ch == CH2) {
        gpio_state_ch2 |= (set_mask & BTN_MASK_CH2);
    }
    gpio_apply(g);
}

static inline void gpio_clear(XGpio *g, u32 ch, u32 clr_mask)
{
    if (ch == CH1) {
        gpio_state_ch1 &= ~(clr_mask & BTN_MASK_CH1);
    } else if (ch == CH2) {
        gpio_state_ch2 &= ~(clr_mask & BTN_MASK_CH2);
    }
    gpio_apply(g);
}

static inline void gpio_pulse(XGpio *g, u32 ch, u32 bitmask, u32 hold_us)
{
    gpio_set(g, ch, bitmask);
    usleep(hold_us);
    gpio_clear(g, ch, bitmask);
    usleep(hold_us);
}

static inline void dsp_use_set(XGpio *g, int level)
{
    if (level)
        gpio_set(g, CH2, BTN_DSP_USE);
    else
        gpio_clear(g, CH2, BTN_DSP_USE);
}

int main(void)
{
    XGpio Gpio;
    XGpio_Config *Cfg = XGpio_LookupConfig(0);
    if (Cfg == NULL) {
        xil_printf("XGpio_LookupConfig failed\r\n");
        return XST_FAILURE;
    }
    if (XGpio_CfgInitialize(&Gpio, Cfg, Cfg->BaseAddress) != XST_SUCCESS) {
        xil_printf("XGpio_CfgInitialize failed\r\n");
        return XST_FAILURE;
    }

    XGpio_SetDataDirection(&Gpio, CH1, 0x00000000U);
    XGpio_SetDataDirection(&Gpio, CH2, 0x00000000U);


    gpio_state_ch1 = 0U;
    gpio_state_ch2 = 0U;
    gpio_apply(&Gpio);

     dsp_use_set(&Gpio, 1);
     usleep(1000);

    const u32 T = 1000U;

  

      gpio_pulse(&Gpio, CH1, BTN_INC_A, T);
        gpio_pulse(&Gpio, CH1, BTN_INC_A, T);
          gpio_pulse(&Gpio, CH1, BTN_INC_A, T);
      gpio_pulse(&Gpio, CH1, BTN_MODE_STEP, T);
    gpio_pulse(&Gpio, CH1, BTN_INC_B, T);
  gpio_pulse(&Gpio, CH1, BTN_MODE_STEP, T);

   

    while (1) {
        // idle 
    }
}
