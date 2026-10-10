#include "cmsis_os.h"
#include "can_telemetry.hpp"
#include "io/can/can.hpp"
#include "motor/rm_motor/rm_motor.hpp"

namespace
{
constexpr float CAN_BITRATE_BPS = 1000000.0f;
// Standard data frame with 8 data bytes, including the 3-bit IFS.
// Bit stuffing is not included, so this is a lower-bound estimate.
constexpr float CAN_FRAME_BITS_MIN = 111.0f;
constexpr uint32_t MONITOR_PERIOD_MS = 1000;
constexpr float MOTOR_COMMAND_NM = 0.0f;  // Set to 0.1f for a safe no-load test.

volatile uint32_t rx_frame_count = 0;
volatile uint32_t tx_frame_count = 0;
}  // namespace

sp::CAN can1(&hcan1);
sp::RM_Motor motor6020(1, sp::RM_Motors::GM6020);

volatile float can_bus_load_percent = 0.0f;
volatile uint32_t can_rx_frames_per_second = 0;
volatile uint32_t can_tx_frames_per_second = 0;

extern "C" void can_task()
{
  osDelay(500);
  can1.config();
  can1.start();

  uint32_t last_monitor_ms = osKernelSysTick();

  while (true) {
    motor6020.cmd(MOTOR_COMMAND_NM);
    motor6020.write(can1.tx_data);
    can1.send(motor6020.tx_id);
    ++tx_frame_count;

    const uint32_t now_ms = osKernelSysTick();
    if (now_ms - last_monitor_ms >= MONITOR_PERIOD_MS) {
      const uint32_t rx_frames = rx_frame_count;
      const uint32_t tx_frames = tx_frame_count;
      rx_frame_count = 0;
      tx_frame_count = 0;

      can_rx_frames_per_second = rx_frames;
      can_tx_frames_per_second = tx_frames;

      const float bits_on_bus = static_cast<float>(rx_frames + tx_frames) * CAN_FRAME_BITS_MIN;
      can_bus_load_percent = 100.0f * bits_on_bus / CAN_BITRATE_BPS;
      last_monitor_ms = now_ms;
    }

    osDelay(1);
  }
}

extern "C" void HAL_CAN_RxFifo0MsgPendingCallback(CAN_HandleTypeDef * hcan)
{
  if (hcan != &hcan1) return;

  const uint32_t stamp_ms = osKernelSysTick();

  while (HAL_CAN_GetRxFifoFillLevel(hcan, CAN_RX_FIFO0) > 0) {
    can1.recv();
    ++rx_frame_count;

    if (can1.rx_id == motor6020.rx_id) {
      motor6020.read(can1.rx_data, stamp_ms);
    }
  }
}
