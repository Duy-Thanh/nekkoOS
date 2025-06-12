# Bootloader Makefile
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
	mkdir -p $(BUILD_DIR)

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
	cp $(STAGE1_BIN) $(BOOTLOADER_BIN)
	# Pad stage1 to exactly 512 bytes
	truncate -s 512 $(BOOTLOADER_BIN) 2>/dev/null || (dd if=/dev/zero bs=512 count=1 of=$(BOOTLOADER_BIN).tmp && dd if=$(STAGE1_BIN) of=$(BOOTLOADER_BIN).tmp conv=notrunc && mv $(BOOTLOADER_BIN).tmp $(BOOTLOADER_BIN))
	# Append stage2
	cat $(STAGE2_BIN) >> $(BOOTLOADER_BIN)
	@echo "Combined bootloader built: $(BOOTLOADER_BIN)"

# Clean build artifacts
clean:
	@echo "Cleaning bootloader build artifacts..."
	rm -f $(STAGE1_BIN) $(STAGE2_BIN) $(BOOTLOADER_BIN)

# Check if NASM is available
check-nasm:
	@which $(NASM) > /dev/null || (echo "Error: NASM not found. Please install NASM assembler." && exit 1)
	@echo "NASM found: $(shell $(NASM) -v)"

# Show bootloader info
info:
	@echo "Bootloader Build Information:"
	@echo "============================="
	@echo "NASM:         $(NASM)"
	@echo "Stage 1 src:  $(STAGE1_SRC)"
	@echo "Stage 2 src:  $(STAGE2_SRC)"
	@echo "Output:       $(BOOTLOADER_BIN)"
