###############################################
# Professional Makefile for CH32V RISC-V MCUs
# Compatible with Windows and Linux
###############################################

###############################################
# Project Configuration
###############################################

PROJECT     := main
BUILD_DIR   := build
OUTPUT_DIR  := $(BUILD_DIR)/output

# MCU Configuration - Change this for different CH32V series
# Supported: ch32v103, ch32v20x, ch32v30x, ch32v003
MCU_FAMILY  := ch32v20x
MCU_VARIANT := D6

# Target-specific settings
ifeq ($(MCU_FAMILY),ch32v003)
  ARCH_FLAGS := -march=rv32ec -mabi=ilp32e
else ifeq ($(MCU_FAMILY),ch32v103)
  ARCH_FLAGS := -march=rv32imac -mabi=ilp32
else ifeq ($(MCU_FAMILY),ch32v20x)
  ARCH_FLAGS := -march=rv32imac -mabi=ilp32
else ifeq ($(MCU_FAMILY),ch32v30x)
  ARCH_FLAGS := -march=rv32imac -mabi=ilp32
else
  $(error Unsupported MCU_FAMILY: $(MCU_FAMILY))
endif

# Source directories
SRCDIRS     := \
  core/src \
  lib/src \
  $(MCU_FAMILY)/src \
  FreeRTOS \
  FreeRTOS/portable/GCC/RISC-V \
  FreeRTOS/portable/MemMang


# Include directories
INCLUDES    := \
  -Icore/inc \
  -Ilib/inc \
  -I$(MCU_FAMILY)/inc \
  -I$(MCU_FAMILY) \
  -IFreeRTOS/include \
  -IFreeRTOS/portable/GCC/RISC-V

# Startup & linker files
STARTUP     := $(MCU_FAMILY)/startup_$(MCU_FAMILY)_$(MCU_VARIANT).S
LDSCRIPT    := $(MCU_FAMILY)/Link.ld

###############################################
# OS Detection and Toolchain Setup
###############################################

# OS Detection
ifeq ($(OS),Windows_NT)
  DETECTED_OS := Windows
  PATH_SEP := \\
  EXE_EXT := .exe
else
  DETECTED_OS := $(shell uname -s)
  PATH_SEP := /
  EXE_EXT :=
endif

# Cross-platform file operations
ifeq ($(DETECTED_OS),Windows)
  RM = if exist "$(subst /,\,$(1))" rmdir /s /q "$(subst /,\,$(1))"
  RMFILE = if exist "$(subst /,\,$(1))" del /q "$(subst /,\,$(1))"
  MKDIR = if not exist "$(subst /,\,$(1))" mkdir "$(subst /,\,$(1))"
  FIXPATH = $(subst /,\,$1)
else
  RM = rm -rf $(1)
  RMFILE = rm -f $(1)
  MKDIR = mkdir -p $(1)
  FIXPATH = $1
endif

# Toolchain paths
CC_PATH_WIN  := C:/MounRiver/MounRiver_Studio2/resources/app/resources/win32/components/WCH/Toolchain/RISC-V Embedded GCC/bin
CC_PATH_LINUX := riscv-none-embed

# Toolchain selection
ifeq ($(DETECTED_OS),Windows)
  CC       := "$(CC_PATH_WIN)/riscv-none-embed-gcc$(EXE_EXT)"
  CXX      := "$(CC_PATH_WIN)/riscv-none-embed-g++$(EXE_EXT)"
  AS       := "$(CC_PATH_WIN)/riscv-none-embed-gcc$(EXE_EXT)"
  AR       := "$(CC_PATH_WIN)/riscv-none-embed-ar$(EXE_EXT)"
  LD       := "$(CC_PATH_WIN)/riscv-none-embed-ld$(EXE_EXT)"
  OBJCOPY  := "$(CC_PATH_WIN)/riscv-none-embed-objcopy$(EXE_EXT)"
  OBJDUMP  := "$(CC_PATH_WIN)/riscv-none-embed-objdump$(EXE_EXT)"
  SIZE     := "$(CC_PATH_WIN)/riscv-none-embed-size$(EXE_EXT)"
  GDB      := "$(CC_PATH_WIN)/riscv-none-embed-gdb$(EXE_EXT)"
else
  CC       := $(CC_PATH_LINUX)-gcc
  CXX      := $(CC_PATH_LINUX)-g++
  AS       := $(CC_PATH_LINUX)-gcc
  AR       := $(CC_PATH_LINUX)-ar
  LD       := $(CC_PATH_LINUX)-ld
  OBJCOPY  := $(CC_PATH_LINUX)-objcopy
  OBJDUMP  := $(CC_PATH_LINUX)-objdump
  SIZE     := $(CC_PATH_LINUX)-size
  GDB      := $(CC_PATH_LINUX)-gdb
endif

###############################################
# Compiler and Linker Flags
###############################################

# Common compiler flags
COMMON_FLAGS := $(ARCH_FLAGS) \
                -msmall-data-limit=8 \
                -ffunction-sections \
                -fdata-sections \
                -fno-common

# C compiler flags
CFLAGS  := $(COMMON_FLAGS) \
           -std=gnu17 \
           -O0 \
           -ggdb3 \
           -Wall \
           -Wextra \
           -Wunused \
           -Wuninitialized \
           -Wshadow \
           -Wno-unused-parameter

# Assembly flags
ASFLAGS := $(COMMON_FLAGS) \
           -x assembler-with-cpp

# Linker flags
LDFLAGS := $(ARCH_FLAGS) \
           -T$(LDSCRIPT) \
           -nostartfiles \
           -Wl,--gc-sections \
           -Wl,--print-memory-usage \
           -Wl,-Map=$(OUTPUT_DIR)/$(PROJECT).map \
           -specs=nano.specs \
           -specs=nosys.specs

# Libraries
LIBS := -lc -lm -lnosys

# Debug/Release configuration
# ifdef DEBUG
#   CFLAGS += -DDEBUG -O0
#   LDFLAGS += -O0
# else
#   CFLAGS += -DNDEBUG -Os
#   LDFLAGS += -Os
# endif

###############################################
# File Collection and Build Rules
###############################################

# Source files
C_SOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))
ASM_SOURCES := $(STARTUP)  

# Object files
C_OBJECTS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SOURCES))
ASM_OBJECTS := $(patsubst %.S,$(BUILD_DIR)/%.o,$(ASM_SOURCES))
OBJECTS := $(C_OBJECTS) $(ASM_OBJECTS)

# Output files
ELF := $(OUTPUT_DIR)/$(PROJECT).elf
BIN := $(OUTPUT_DIR)/$(PROJECT).bin
HEX := $(OUTPUT_DIR)/$(PROJECT).hex
MAP := $(OUTPUT_DIR)/$(PROJECT).map
LSS := $(OUTPUT_DIR)/$(PROJECT).lss

# Dependency files
DEPS := $(C_OBJECTS:.o=.d)

###############################################
# Build Targets
###############################################

# Default target
all: info $(ELF) $(BIN) $(HEX) $(LSS) size

# Display build information
info:
	@echo "========================================="
	@echo "Building $(PROJECT) for $(MCU_FAMILY)"
	@echo "Target: $(MCU_FAMILY)_$(MCU_VARIANT)"
	@echo "OS: $(DETECTED_OS)"
	@echo "Compiler: $(CC)"
	@echo "Startup file: $(STARTUP)"
	@echo "ASM Sources: $(ASM_SOURCES)"
	@echo "ASM Objects: $(ASM_OBJECTS)"
	@echo "========================================="

# Create necessary directories
$(BUILD_DIR) $(OUTPUT_DIR):
	@$(call MKDIR,$@)

# Compile C source files
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "Compiling: $<"
	@$(call MKDIR,$(dir $@))
	@$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

# Assemble source files
$(BUILD_DIR)/%.o: %.S | $(BUILD_DIR)
	@echo "Assembling: $<"
	@$(call MKDIR,$(dir $@))
	@$(AS) $(ASFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

# Link ELF file
$(ELF): $(OBJECTS) | $(OUTPUT_DIR)
	@echo "Linking: $@"
	@$(CC) $(OBJECTS) $(LDFLAGS) $(LIBS) -o $@

# Generate binary file
$(BIN): $(ELF)
	@echo "Creating: $@"
	@$(OBJCOPY) -O binary $< $@

# Generate hex file
$(HEX): $(ELF)
	@echo "Creating: $@"
	@$(OBJCOPY) -O ihex $< $@

# Generate disassembly listing
$(LSS): $(ELF)
	@echo "Creating: $@"
	@$(OBJDUMP) -h -S $< > $@

# Display size information
size: $(ELF)
	@echo "========================================="
	@echo "Size Information:"
	@$(SIZE) $<
	@echo "========================================="

# Include dependency files
-include $(DEPS)

###############################################
# Utility Targets
###############################################

# Clean build files
clean:
	@echo "Cleaning build files..."
	@$(call RM,$(OUTPUT_DIR))
	@$(call RM,$(BUILD_DIR))

# Deep clean (including output)

# Flash firmware using OpenOCD
flash: $(ELF)
	@echo "Flashing $(ELF)..."
	@openocd -f wch-riscv.cfg -c "program $< verify reset exit"

# Robust flash with recovery


# Flash with physical reset (most reliable)


# Start OpenOCD debug server
debug: $(ELF)
	@echo "Starting OpenOCD debug server..."
	@openocd -f wch-riscv.cfg

# Start GDB debug session
gdb: $(ELF)
	@echo "Starting GDB debug session..."
	@$(GDB) $<

# Erase chip
erase:
	@echo "Erasing chip..."
	@openocd -f wch-riscv.cfg -c "init; reset halt; flash erase_sector wch_riscv 0 last; exit"

# Reset target
reset:
	@echo "Resetting target..."
	@openocd -f wch-riscv.cfg -c "init; reset; exit"

# Show memory usage
meminfo: $(ELF)
	@echo "Memory usage information:"
	@$(SIZE) -A $<

# Generate assembly listing from C source
%.s: %.c
	@$(CC) $(CFLAGS) $(INCLUDES) -S $< -o $@

# Create release package
release: clean all
	@echo "Creating release package..."
	@$(call MKDIR,release)
	@cp $(BIN) release/$(PROJECT)_$(MCU_FAMILY)_v$(shell date +%Y%m%d).bin
	@cp $(HEX) release/$(PROJECT)_$(MCU_FAMILY)_v$(shell date +%Y%m%d).hex
	@cp $(MAP) release/$(PROJECT)_$(MCU_FAMILY)_v$(shell date +%Y%m%d).map

# Show help
help:
	@echo "Available targets:"
	@echo "  all              - Build all output files (default)"
	@echo "  clean            - Remove build files"
	@echo "  distclean        - Remove build and output files"
	@echo "  flash            - Flash firmware to target (standard)"
	@echo "  flash-robust     - Flash with recovery procedures"
	@echo "  flash-physical   - Flash with physical reset (most reliable)"
	@echo "  flash-force      - Force flash with slow timing"
	@echo "  debug            - Start OpenOCD debug server"
	@echo "  debug-enhanced   - Start enhanced OpenOCD debug server"
	@echo "  debug-physical   - Start OpenOCD with physical reset support"
	@echo "  reset-physical   - Perform physical reset recovery"
	@echo "  connect-physical - Connect with physical reset assistance"
	@echo "  gdb              - Start GDB debug session"
	@echo "  erase            - Erase target flash"
	@echo "  reset            - Reset target"
	@echo "  meminfo          - Show memory usage"
	@echo "  release          - Create release package"
	@echo "  size             - Show size information"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Build variables:"
	@echo "  MCU_FAMILY = $(MCU_FAMILY)"
	@echo "  MCU_VARIANT = $(MCU_VARIANT)"
	@echo "  DEBUG = $(DEBUG) (set to 1 for debug build)"
	@echo ""
	@echo "Example usage:"
	@echo "  make                    # Build for default target"
	@echo "  make MCU_FAMILY=ch32v103 # Build for CH32V103"
	@echo "  make DEBUG=1            # Build with debug symbols"
	@echo "  make -j8                # Parallel build with 8 jobs"

###############################################
# Special Targets
###############################################

.PHONY: all info clean distclean flash debug gdb erase reset size meminfo release help
.SECONDARY: $(OBJECTS)
