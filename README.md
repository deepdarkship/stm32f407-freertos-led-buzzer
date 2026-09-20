# STM32F407 FreeRTOS LED + Buzzer

基于 STM32CubeMX、STM32F407IGH6 和
[`sp_middleware`](https://github.com/TongjiSuperPower/sp_middleware) 的 FreeRTOS 示例。

## 功能

- 上电/烧录复位后，蜂鸣器以 5 kHz 响 3 声，每声 100 ms，间隔 100 ms。
- RGB LED 持续执行约 2 s 渐亮、2 s 渐暗的呼吸效果。
- `led_task` 与 `buzzer_task` 是两个独立的 FreeRTOS 任务，执行时互不阻塞。

## CubeMX 配置

| 功能 | 外设 | 引脚 | 配置 |
| --- | --- | --- | --- |
| RGB LED - R | TIM5_CH1 | PH10 | PWM Generation CH1 |
| RGB LED - G | TIM5_CH2 | PH11 | PWM Generation CH2 |
| RGB LED - B | TIM5_CH3 | PH12 | PWM Generation CH3 |
| 蜂鸣器 | TIM4_CH3 | PB8 | PWM Generation CH3 |
| 调试 | SWD | PA13 / PA14 | Serial Wire |
| 系统时基 | TIM14 | - | 避免与 FreeRTOS SysTick 冲突 |

FreeRTOS 使用 CMSIS-RTOS v1，包含：

- `defaultTask`
- `LEDTask` -> `led_task`
- `BuzzerTask` -> `buzzer_task`

`TIM4` 位于 APB1，定时器时钟为 84 MHz；`Buzzer` 驱动使用该频率计算
PWM 周期。C 板的 LED PWM 与蜂鸣器 PWM 均由 `sp_middleware` 驱动。

## 编译

先递归拉取子模块，再配置和编译：

```bash
git clone --recursive <repository-url>
cd <repository>
cmake --preset Debug
cmake --build --preset Debug --parallel
```

生成文件位于 `build/Debug/led_buzzer.elf`。

## 烧录

工程提供 `.vscode/tasks.json`，可使用 `OpenOCD: flash` 任务烧录。
`openocd.cfg` 默认选择 CMSIS-DAP；使用 ST-Link 时，切换其中的 interface
配置为：

```tcl
source [find interface/stlink.cfg]
```

也可以在项目根目录执行：

```bash
openocd -f openocd.cfg -c "program build/Debug/led_buzzer.elf verify reset exit"
```

## 二次使用 CubeMX

1. 用 STM32CubeMX 打开 `led_buzzer.ioc`。
2. 保持 Project Manager 的输出目录为仓库根目录。
3. 生成代码后，CubeMX 会更新 `Core/`、`Drivers/`、`Middlewares/` 及
   `cmake/stm32cubemx/CMakeLists.txt`。
4. 根目录 `CMakeLists.txt` 是一次性模板，其中已加入应用源码和
   `sp_middleware` 路径，不要删除这些条目。

## 依赖

- STM32CubeMX 6.18.1
- STM32Cube FW_F4 1.28.3
- CMake 3.22+
- Ninja
- GNU Arm Embedded Toolchain
- `sp_middleware` 官方 Git 仓库
