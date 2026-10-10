#include "cmsis_os.h"
#include "can_telemetry.hpp"
#include "io/plotter/plotter.hpp"
#include "motor/rm_motor/rm_motor.hpp"

extern sp::RM_Motor motor6020;

sp::Plotter plotter(&huart1);

extern "C" void plotter_task(void const * argument)
{
  (void)argument;

  while (true) {
    plotter.plot(
      motor6020.speed,
      motor6020.angle,
      motor6020.torque,
      static_cast<float>(motor6020.temperature),
      can_bus_load_percent,
      static_cast<float>(can_rx_frames_per_second));
    osDelay(1);
  }
}