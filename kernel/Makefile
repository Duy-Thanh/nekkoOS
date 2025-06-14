# Kernel Makefile
# Builds the nekkoOS 32-bit kernel

# Toolchain
CC = i686-elf-gcc
AS = i686-elf-as
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
OBJDUMP = i686-elf-objdump

# Directories
ARCH_DIR = arch/i386
MM_DIR = mm
INCLUDE_DIR = include
BUILD_DIR = ../build

# Compiler flags
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -nostdlib -nostdinc
CFLAGS += -fno-builtin -fno-stack-protector -fno-pic -fno-pie
CFLAGS += -m32 -march=i686 -mtune=i686
CFLAGS += -I$(INCLUDE_DIR)

# Assembler flags
ASFLAGS = --32

# Linker flags
LDFLAGS = -m elf_i386 -nostdlib -T kernel.ld

# Source files
C_SOURCES = $(wildcard *.c) $(wildcard $(ARCH_DIR)/*.c) $(wildcard $(MM_DIR)/*.c)
ASM_SOURCES = $(wildcard *.s) $(wildcard $(ARCH_DIR)/*.s)

# Object files
C_OBJECTS = $(C_SOURCES:.c=.o)
ASM_OBJECTS = $(ASM_SOURCES:.s=.o)
OBJECTS = $(C_OBJECTS) $(ASM_OBJECTS)

# Output files
KERNEL_ELF = $(BUILD_DIR)/kernel.elf
KERNEL_BIN = $(BUILD_DIR)/kernel.bin

.PHONY: all clean kernel

# Default target
all: $(KERNEL_BIN)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build kernel binary
$(KERNEL_BIN): $(KERNEL_ELF)
	@echo "Creating kernel binary..."
	$(OBJCOPY) -O binary $(KERNEL_ELF) $(KERNEL_BIN)
	@echo "Kernel binary created: $(KERNEL_BIN)"

# Link kernel ELF
$(KERNEL_ELF): $(OBJECTS) $(BUILD_DIR)
	@echo "Linking kernel..."
	$(LD) $(LDFLAGS) -o $(KERNEL_ELF) $(OBJECTS)
	@echo "Kernel ELF created: $(KERNEL_ELF)"

# Compile C source files
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble assembly source files
%.o: %.s
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	@echo "Cleaning kernel build artifacts..."
	@if exist "kernel.o" del "kernel.o" >nul 2>&1
	@if exist "string.o" del "string.o" >nul 2>&1
	@if exist "arch\i386\boot.o" del "arch\i386\boot.o" >nul 2>&1
	@if exist "$(KERNEL_ELF)" del "$(KERNEL_ELF)" >nul 2>&1
	@if exist "$(KERNEL_BIN)" del "$(KERNEL_BIN)" >nul 2>&1
	@echo "Kernel clean complete."

# Show kernel disassembly
disasm: $(KERNEL_ELF)
	$(OBJDUMP) -d $(KERNEL_ELF) > $(BUILD_DIR)/kernel.dis
	@echo "Disassembly saved to $(BUILD_DIR)/kernel.dis"

# Show kernel symbols
symbols: $(KERNEL_ELF)
	$(OBJDUMP) -t $(KERNEL_ELF) > $(BUILD_DIR)/kernel.sym
	@echo "Symbols saved to $(BUILD_DIR)/kernel.sym"

# Show kernel info
info:
	@echo "Kernel Build Information:"
	@echo "========================="
	@echo "CC:           $(CC)"
	@echo "CFLAGS:       $(CFLAGS)"
	@echo "LD:           $(LD)"
	@echo "LDFLAGS:      $(LDFLAGS)"
	@echo "C_SOURCES:    $(C_SOURCES)"
	@echo "ASM_SOURCES:  $(ASM_SOURCES)"
	@echo "OBJECTS:      $(OBJECTS)"
	@echo "OUTPUT:       $(KERNEL_BIN)"

# Check toolchain
check:
	@echo "Checking kernel build toolchain..."
	@which $(CC) > /dev/null || (echo "Error: $(CC) not found" && exit 1)
	@which $(AS) > /dev/null || (echo "Error: $(AS) not found" && exit 1)
	@which $(LD) > /dev/null || (echo "Error: $(LD) not found" && exit 1)
	@echo "Toolchain check passed."
