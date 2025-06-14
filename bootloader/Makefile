# Bootloader Makefile for Windows
# Builds Stage 1 (MBR) and Stage 2 bootloaders

# Tools
NASM = nasm
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

# Directories
STAGE1_DIR = stage1
STAGE2_DIR = stage2
BUILD_DIR = ../build

# Source files
STAGE1_SRC = $(STAGE1_DIR)/boot.asm
STAGE2_SRC = $(STAGE2_DIR)/stage2.asm

# Output files
STAGE1_BIN = $(BUILD_DIR)/stage1.bin
STAGE2_BIN = $(BUILD_DIR)/stage2.bin
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin

# Flags
NASM_FLAGS = -f bin

.PHONY: all clean stage1 stage2

# Default target
all: $(BOOTLOADER_BIN)

# Create build directory
$(BUILD_DIR):
	@if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"

# Build Stage 1 bootloader
stage1: $(STAGE1_BIN)

$(STAGE1_BIN): $(STAGE1_SRC) $(BUILD_DIR)
	@echo "Assembling Stage 1 bootloader..."
	$(NASM) $(NASM_FLAGS) $(STAGE1_SRC) -o $(STAGE1_BIN)
	@echo "Stage 1 bootloader built: $(STAGE1_BIN)"

# Build Stage 2 bootloader
stage2: $(STAGE2_BIN)

$(STAGE2_BIN): $(STAGE2_SRC) $(BUILD_DIR)
	@echo "Assembling Stage 2 bootloader..."
	$(NASM) $(NASM_FLAGS) $(STAGE2_SRC) -o $(STAGE2_BIN)
	@echo "Stage 2 bootloader built: $(STAGE2_BIN)"

# Combine bootloaders into single file
$(BOOTLOADER_BIN): $(STAGE1_BIN) $(STAGE2_BIN)
	@echo "Combining bootloader stages..."
	@cd .. && cmd /c "copy /b build\stage1.bin + build\stage2.bin build\bootloader.bin"
	@echo "Combined bootloader built: $(BOOTLOADER_BIN)"

# Clean build artifacts
clean:
	@echo "Cleaning bootloader build artifacts..."
	@if exist "$(STAGE1_BIN)" del "$(STAGE1_BIN)" >nul 2>&1
	@if exist "$(STAGE2_BIN)" del "$(STAGE2_BIN)" >nul 2>&1
	@if exist "$(BOOTLOADER_BIN)" del "$(BOOTLOADER_BIN)" >nul 2>&1

# Check if NASM is available
check-nasm:
	@where $(NASM) >nul 2>&1 || (echo "Error: NASM not found. Please install NASM assembler." && exit 1)
	@echo "NASM found:"
	@$(NASM) -v

# Show bootloader info
info:
	@echo "Bootloader Build Information:"
	@echo "============================="
	@echo "NASM:         $(NASM)"
	@echo "Stage 1 src:  $(STAGE1_SRC)"
	@echo "Stage 2 src:  $(STAGE2_SRC)"
	@echo "Output:       $(BOOTLOADER_BIN)"

# Size information
size: $(BOOTLOADER_BIN)
	@echo "Bootloader Size Information:"
	@echo "============================"
	@if exist "$(STAGE1_BIN)" (for %%I in ("$(STAGE1_BIN)") do echo "Stage 1: %%~zI bytes")
	@if exist "$(STAGE2_BIN)" (for %%I in ("$(STAGE2_BIN)") do echo "Stage 2: %%~zI bytes")
	@if exist "$(BOOTLOADER_BIN)" (for %%I in ("$(BOOTLOADER_BIN)") do echo "Total: %%~zI bytes")