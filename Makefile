# nekkoOS - 32-bit Operating System Makefile
# Main build system for bootloader, kernel, and userspace

# Toolchain Configuration
CC = i686-elf-gcc
AS = i686-elf-as
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
OBJDUMP = i686-elf-objdump
STRIP = i686-elf-strip

# Directories
BOOTLOADER_DIR = bootloader
KERNEL_DIR = kernel
USERSPACE_DIR = userspace
TOOLS_DIR = tools
BUILD_DIR = build
ISO_DIR = $(BUILD_DIR)/iso

# Output files
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
OS_IMAGE = $(BUILD_DIR)/nekkoOS.img
OS_ISO = $(BUILD_DIR)/nekkoOS.iso

# Image configuration
FLOPPY_SIZE = 1440k
HD_SIZE = 32M

# QEMU configuration
QEMU = qemu-system-i386
QEMU_FLAGS = -m 32M -serial stdio

.PHONY: all clean bootloader kernel userspace image iso run run-iso debug help

# Default target
all: image

# Help target
help:
	@echo "nekkoOS Build System"
	@echo "==================="
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build everything (default: image)"
	@echo "  bootloader - Build bootloader"
	@echo "  kernel     - Build kernel"
	@echo "  userspace  - Build userspace applications"
	@echo "  image      - Create OS disk image"
	@echo "  iso        - Create ISO image"
	@echo "  run        - Run OS in QEMU"
	@echo "  run-iso    - Run ISO in QEMU"
	@echo "  debug      - Run OS in QEMU with GDB support"
	@echo "  clean      - Clean all build artifacts"
	@echo "  help       - Show this help message"

# Create build directory
$(BUILD_DIR):
	@if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"

# Build bootloader
bootloader: $(BUILD_DIR)
	@echo "Building bootloader..."
	$(MAKE) -C $(BOOTLOADER_DIR) BUILD_DIR=../$(BUILD_DIR)

# Build kernel
kernel: $(BUILD_DIR)
	@echo "Building kernel..."
	$(MAKE) -C $(KERNEL_DIR) BUILD_DIR=../$(BUILD_DIR)

# Build userspace
userspace: $(BUILD_DIR)
	@echo "Building userspace..."
	$(MAKE) -C $(USERSPACE_DIR) BUILD_DIR=../$(BUILD_DIR)

# Create OS disk image
image: bootloader kernel $(BUILD_DIR)
	@echo "Creating OS disk image..."
	@fsutil file createnew "$(OS_IMAGE)" 33554432 >nul
	@echo "Writing bootloader to disk image..."
	@powershell -Command "$$bootloader = [System.IO.File]::ReadAllBytes('$(BOOTLOADER_BIN)'); $$image = [System.IO.File]::ReadAllBytes('$(OS_IMAGE)'); [Array]::Copy($$bootloader, 0, $$image, 0, [Math]::Min($$bootloader.Length, 512)); [System.IO.File]::WriteAllBytes('$(OS_IMAGE)', $$image)"
	@echo "Disk image created: $(OS_IMAGE)"

# Create ISO image using GRUB
iso: kernel $(BUILD_DIR)
	@echo "Creating ISO image..."
	@if not exist "$(ISO_DIR)\boot\grub" mkdir "$(ISO_DIR)\boot\grub"
	@copy "$(KERNEL_BIN)" "$(ISO_DIR)\boot\kernel.bin" >nul
	@echo menuentry "nekkoOS" { > "$(ISO_DIR)\boot\grub\grub.cfg"
	@echo     multiboot /boot/kernel.bin >> "$(ISO_DIR)\boot\grub\grub.cfg"
	@echo } >> "$(ISO_DIR)\boot\grub\grub.cfg"
	@grub-mkrescue -o "$(OS_ISO)" "$(ISO_DIR)"
	@echo "ISO image created: $(OS_ISO)"

# Run OS in QEMU
run: image
	@echo "Starting nekkoOS in QEMU..."
	$(QEMU) $(QEMU_FLAGS) -drive file=$(OS_IMAGE),format=raw

# Run ISO in QEMU
run-iso: iso
	@echo "Starting nekkoOS ISO in QEMU..."
	$(QEMU) $(QEMU_FLAGS) -cdrom $(OS_ISO)

# Run with GDB debugging support
debug: image
	@echo "Starting nekkoOS in QEMU with GDB support..."
	@echo "Connect GDB with: target remote localhost:1234"
	$(QEMU) $(QEMU_FLAGS) -drive file=$(OS_IMAGE),format=raw -s -S

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@if exist "$(BUILD_DIR)" rmdir /s /q "$(BUILD_DIR)" >nul 2>&1
	@$(MAKE) -C $(BOOTLOADER_DIR) clean
	@$(MAKE) -C $(KERNEL_DIR) clean
	@$(MAKE) -C $(USERSPACE_DIR) clean
	@echo "Clean complete."

# Check toolchain
check-toolchain:
	@echo "Checking toolchain..."
	@where $(CC) >nul 2>&1 || (echo "Error: $(CC) not found in PATH" && exit 1)
	@where $(AS) >nul 2>&1 || (echo "Error: $(AS) not found in PATH" && exit 1)
	@where $(LD) >nul 2>&1 || (echo "Error: $(LD) not found in PATH" && exit 1)
	@echo "Toolchain check passed."

# Install dependencies (placeholder)
install-deps:
	@echo "Install dependencies manually:"
	@echo "1. Download i686-elf-tools for Windows"
	@echo "2. Install QEMU"
	@echo "3. Install NASM assembler"
	@echo "4. Add tools to PATH"

# Print configuration
config:
	@echo "Build Configuration:"
	@echo "==================="
	@echo "CC:           $(CC)"
	@echo "AS:           $(AS)"
	@echo "LD:           $(LD)"
	@echo "BUILD_DIR:    $(BUILD_DIR)"
	@echo "OS_IMAGE:     $(OS_IMAGE)"
	@echo "QEMU:         $(QEMU)"
	@echo "QEMU_FLAGS:   $(QEMU_FLAGS)"
