#ifndef CAN_TELEMETRY_HPP
#define CAN_TELEMETRY_HPP

#include <cstdint>

// Updated once per second by can_task().
extern volatile float can_bus_load_percent;
extern volatile uint32_t can_rx_frames_per_second;
extern volatile uint32_t can_tx_frames_per_second;

#endif  // CAN_TELEMETRY_HPP