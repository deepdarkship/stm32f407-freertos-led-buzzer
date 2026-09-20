#include "cmsis_os.h"
#include "io/led/led.hpp"

sp::LED led(&htim5);

extern "C" void led_task(void const * argument)
{
  (void)argument;
  led.start();

  while (true) {
    for (uint8_t step = 0; step <= 50; ++step) {
      const float brightness = step * 0.02f;
      led.set(brightness, 0.0f, brightness * 0.25f);
      osDelay(20);
    }

    for (uint8_t step = 50; step > 0; --step) {
      const float brightness = step * 0.02f;
      led.set(brightness, 0.0f, brightness * 0.25f);
      osDelay(20);
    }
  }
}
