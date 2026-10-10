# STM32F407 FreeRTOS CAN 通信实践

基于 STM32CubeMX、STM32F407IGH6、FreeRTOS 和
[`sp_middleware`](https://github.com/TongjiSuperPower/sp_middleware) 的第三讲实践工程。

## 已实现功能

- 保留第二讲的 RGB LED 呼吸灯和蜂鸣器开机提示。
- USART1 以 921600 bps、8N1 输出 `sp::Plotter` 二进制数据帧。
- CAN1 以 1 Mbps 标准帧周期性发送 GM6020 控制帧。
- 接收并解析 ID 为 1 的 GM6020 反馈帧。
- 串口输出电机速度、角度、转矩、温度以及 CAN 总线统计量。
- 每 1 s 统计收发帧数和估算总线负载；估算结果为不计位填充的下限。

## 外设配置

| 功能 | 外设 | 引脚 | 配置 |
| --- | --- | --- | --- |
| RGB LED | TIM5 CH1/CH2/CH3 | PH10 / PH11 / PH12 | PWM |
| 蜂鸣器 | TIM4 CH3 | PB8 | PWM |
| 串口 | USART1 | PA9 TX / PB7 RX | 921600 bps，8N1 |
| 串口 TX DMA | DMA2 Stream7 | - | Memory to peripheral |
| CAN | CAN1 | PD0 RX / PD1 TX | 1 Mbps，标准帧 |
| 调试 | SWD | PA13 / PA14 | Serial Wire |
| 系统时基 | TIM14 | - | 避免与 FreeRTOS SysTick 冲突 |

CAN1 时钟为 42 MHz，位时序为 `Prescaler=3`、`BS1=10TQ`、`BS2=3TQ`：

```text
42 MHz / (3 × (1 + 10 + 3)) = 1 Mbps
```

FreeRTOS 任务如下：

- `LEDTask`：LED 呼吸效果。
- `BuzzerTask`：上电响 3 声。
- `PlotterTask`：每 1 ms 发送一组串口曲线数据。
- `CanTask`：每 1 ms 发送电机控制帧、解析反馈并统计总线负载。

## 硬件接线

1. 将 C 板 CAN_H、CAN_L 分别与 GM6020 和 PCAN 的 CAN_H、CAN_L 相连。
2. 总线最两端各保留一个 120 Ω 终端电阻。PCAN 若启用内部终端电阻，则不要再启用
   同侧设备的终端电阻，避免并联后阻值明显小于 120 Ω。
3. 将 GM6020 电机 ID 设为 1，控制方式设为电流控制。
4. 先用支架固定电机并空载测试，不要直接连接机构。

GM6020 ID 1 的报文：

| 方向 | 标识符 | 帧类型 | DLC |
| --- | --- | --- | --- |
| 控制帧 | `0x1FE` | 标准数据帧 | 8 |
| 反馈帧 | `0x205` | 标准数据帧 | 8 |

`0x1FE` 一帧可携带 ID 1 至 4 共四个电机的控制量，因此 8 个电机只需要
2 个控制帧。

## 串口曲线

1. 使用 USB 串口连接 C 板，串口参数设为 `921600 8N1`，无流控。
2. 打开 `serialplot.exe` 或第三讲附件中的串口绘图软件。
3. 将帧格式设置为：

```text
帧头:     AA BB
长度字段: 1 字节，值为后续 float 数据的字节数
数据:     float32 小端序
```

输出通道依次为：

1. 电机速度，单位 `rad/s`
2. 电机角度，单位 `rad`
3. 电机转矩，单位 `N·m`
4. 电机温度，单位 `°C`
5. CAN 总线负载下限估算，单位 `%`
6. 每秒接收 CAN 帧数

`applications/plotter_task.cpp` 中的参数顺序与上面一致。

## 编译与烧录

递归拉取子模块后配置并编译：

```bash
git submodule update --init --recursive
cmake --preset Debug
cmake --build --preset Debug --parallel
```

生成文件位于 `build/Debug/led_buzzer.elf`。

工程提供 `.vscode/tasks.json`，可使用 `OpenOCD: flash` 任务烧录。也可以在项目根
目录执行：

```bash
openocd -f openocd.cfg -c "program build/Debug/led_buzzer.elf verify reset exit"
```

烧录后蜂鸣器先响 3 声。默认电机控制量是 `0.0 N·m`，电机不会主动旋转。完成
接线检查后，将 `applications/can_task.cpp` 中的：

```cpp
constexpr float MOTOR_COMMAND_NM = 0.0f;
```

临时改为：

```cpp
constexpr float MOTOR_COMMAND_NM = 0.1f;
```

重新编译烧录后，电机应低速旋转，串口曲线中的速度和反馈温度开始变化。测试结束
后应改回 `0.0f` 或断电。

## 读取数据帧和计算负载

1. 将 PCAN 设为 1 Mbps 正常模式并接入总线。
2. 打开 PCAN-View，观察 `0x1FE` 控制帧和 `0x205` 反馈帧。
3. 使用 PCAN-View 的 Trace/Log 功能保存一段时间的报文。
4. 将报文数量、DLC 和波特率输入课程给出的
   [CAN Bus Load Calculator](https://lc6464.github.io/CANbus-Load-Calculator/)。
5. 也可直接观察工程变量 `can_bus_load_percent`、`can_rx_frames_per_second` 和
   `can_tx_frames_per_second`。这些变量只用于快速检查，PCAN 工具的计算结果更准确。

标准数据帧含 8 字节数据、包含 3 位帧间隔但不计位填充时，理论最短长度为
111 bit。本工程按 1 kHz 发送一个控制帧并接收一个反馈帧，因此单电机测试的理论
下限负载为：

```text
2 × 111 bit / 1 Mbps = 22.2%
```

考虑位填充后，实际负载通常更高，约在 22% 至 27% 之间，应以 PCAN 记录为准。

对于 8 个电机，每秒需要：

- 8 个反馈帧：每个电机 1 kHz。
- 2 个控制帧：每个 `0x1FE/0x1FF` 帧控制 4 个电机。

合计 10 帧/ms，仅按 111 bit/帧计算已经达到：

```text
10 × 111 bit / 1 ms = 1.11 Mbps
```

这已超过 1 Mbps CAN 总线的理论容量，尚未计入位填充、仲裁和错误帧，因此一根
1 Mbps CAN 总线不可能同时以 1 kHz 闭环控制 8 个 GM6020。

## CubeMX 二次生成

`led_buzzer.ioc` 已加入 CAN1、USART1 和 USART1_TX DMA 配置。重新生成代码后，
检查并保留以下内容：

- `Core/Src/can.c`、`Core/Src/dma.c`、`Core/Src/usart.c`
- `Core/Src/stm32f4xx_it.c` 中的 CAN、USART、DMA 中断处理
- 根目录 `CMakeLists.txt` 中的应用源码和 `sp_middleware` 路径
- `cmake/stm32cubemx/CMakeLists.txt` 中新增的 CAN/UART/DMA 源文件

## `arm-none-eabi-gcc` 找不到

工程会搜索 STM32CubeCLT 和 Arm GNU Toolchain 的常见安装路径。也可以显式指定：

```bash
cmake --preset Debug -DARM_GCC_PATH="C:/ST/STM32CubeCLT_1.22.0/GNU-tools-for-STM32/bin"
```

若修改了工具链路径，执行 `CMake: Delete Cache and Reconfigure`，或删除
`build/` 后重新配置。