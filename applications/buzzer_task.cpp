#include "cmsis_os.h"
#include "io/buzzer/buzzer.hpp"

// C board: TIM4_CH3 (PB8), APB1 timer clock is 84 MHz.
sp::Buzzer buzzer(&htim4, TIM_CHANNEL_3, 84e6);

extern "C" void buzzer_task(void const * argument)
{
  (void)argument;
  buzzer.set(5000.0f, 0.1f);

  for (uint8_t i = 0; i < 3; ++i) {
    buzzer.start();
    osDelay(100);
    buzzer.stop();
    osDelay(100);
  }

  while (true) {
    osDelay(1000);
  }
}
