set(CMAKE_SYSTEM_NAME               Generic)
set(CMAKE_SYSTEM_PROCESSOR          arm)

# Optional override:
#   cmake --preset Debug -DARM_GCC_PATH="C:/path/to/GNU-tools-for-STM32/bin"
set(ARM_GCC_PATH "" CACHE PATH "Directory containing arm-none-eabi-gcc")

set(_ARM_GCC_HINTS)
foreach(_hint IN ITEMS
    "${ARM_GCC_PATH}"
    "$ENV{ARM_GCC_PATH}"
    "$ENV{STM32CUBECLT_PATH}"
    "$ENV{ProgramFiles}/STMicroelectronics/STM32CubeCLT/GNU-tools-for-STM32/bin"
    "$ENV{ProgramFiles}/STMicroelectronics/STM32Cube/STM32CubeCLT/GNU-tools-for-STM32/bin"
)
    if(_hint AND IS_DIRECTORY "${_hint}")
        list(APPEND _ARM_GCC_HINTS "${_hint}")
    endif()
endforeach()

file(GLOB _ARM_GCC_CANDIDATES
    "C:/ST/STM32CubeCLT_*/GNU-tools-for-STM32/bin/arm-none-eabi-gcc.*"
    "C:/ST/STM32CubeCLT_*/GNU-tools-for-STM32/bin/arm-none-eabi-gcc"
    "$ENV{ProgramFiles}/STMicroelectronics/STM32CubeCLT/*/GNU-tools-for-STM32/bin/arm-none-eabi-gcc.*"
    "$ENV{ProgramFiles}/STMicroelectronics/STM32Cube/STM32CubeCLT/*/GNU-tools-for-STM32/bin/arm-none-eabi-gcc.*"
    "$ENV{LOCALAPPDATA}/Programs/STM32CubeCLT/*/GNU-tools-for-STM32/bin/arm-none-eabi-gcc.*"
    "C:/ST/STM32CubeIDE_*/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.*/tools/bin/arm-none-eabi-gcc.*"
    "C:/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/*/bin/arm-none-eabi-gcc.*"
    "C:/Program Files/Arm GNU Toolchain arm-none-eabi/*/bin/arm-none-eabi-gcc.*"
)
foreach(_candidate IN LISTS _ARM_GCC_CANDIDATES)
    get_filename_component(_candidate_dir "${_candidate}" DIRECTORY)
    list(APPEND _ARM_GCC_HINTS "${_candidate_dir}")
endforeach()
list(REMOVE_DUPLICATES _ARM_GCC_HINTS)

find_program(ARM_NONE_EABI_GCC
    NAMES arm-none-eabi-gcc
    HINTS ${_ARM_GCC_HINTS}
    DOC "Arm GNU Toolchain C compiler"
)

if(NOT ARM_NONE_EABI_GCC)
    message(FATAL_ERROR
        "arm-none-eabi-gcc was not found. Install STM32CubeCLT or Arm GNU Toolchain, "
        "or configure with -DARM_GCC_PATH=<directory containing arm-none-eabi-gcc>."
    )
endif()

get_filename_component(TOOLCHAIN_BIN "${ARM_NONE_EABI_GCC}" DIRECTORY)
message(STATUS "Using Arm GNU Toolchain from: ${TOOLCHAIN_BIN}")

set(CMAKE_C_COMPILER_ID               GNU)
set(CMAKE_CXX_COMPILER_ID             GNU)

if(ARM_NONE_EABI_GCC MATCHES "\\.[Ee][Xx][Ee]$")
    set(_TOOLCHAIN_EXE_SUFFIX ".exe")
else()
    set(_TOOLCHAIN_EXE_SUFFIX "")
endif()

set(TOOLCHAIN_PREFIX                  "${TOOLCHAIN_BIN}/arm-none-eabi-")
set(CMAKE_C_COMPILER                 "${ARM_NONE_EABI_GCC}")
set(CMAKE_ASM_COMPILER               "${CMAKE_C_COMPILER}")
set(CMAKE_CXX_COMPILER               "${TOOLCHAIN_PREFIX}g++${_TOOLCHAIN_EXE_SUFFIX}")
set(CMAKE_LINKER                     "${TOOLCHAIN_PREFIX}g++${_TOOLCHAIN_EXE_SUFFIX}")
set(CMAKE_OBJCOPY                    "${TOOLCHAIN_PREFIX}objcopy${_TOOLCHAIN_EXE_SUFFIX}")
set(CMAKE_SIZE                       "${TOOLCHAIN_PREFIX}size${_TOOLCHAIN_EXE_SUFFIX}")

set(CMAKE_EXECUTABLE_SUFFIX_ASM     ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_C       ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_CXX     ".elf")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
# MCU specific flags
set(TARGET_FLAGS "-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard ")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${TARGET_FLAGS}")
set(CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS} -x assembler-with-cpp -MMD -MP")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -fdata-sections -ffunction-sections -fstack-usage")

# The cyclomatic-complexity parameter must be defined for the Cyclomatic complexity feature in STM32CubeIDE to work.
# However, most GCC toolchains do not support this option, which causes a compilation error; for this reason, the feature is disabled by default.
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcyclomatic-complexity")

set(CMAKE_C_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_C_FLAGS_RELEASE "-Os -g0")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_CXX_FLAGS_RELEASE "-Os -g0")

set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -fno-rtti -fno-exceptions -fno-threadsafe-statics")

set(CMAKE_EXE_LINKER_FLAGS "${TARGET_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T \"${CMAKE_SOURCE_DIR}/STM32F407xx_FLASH.ld\"")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --specs=nano.specs")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-Map=${CMAKE_PROJECT_NAME}.map -Wl,--gc-sections")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--print-memory-usage")
set(TOOLCHAIN_LINK_LIBRARIES "m")
