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
	mkdir -p $(BUILD_DIR)

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
	# Create empty disk image
	dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=65536
	# Write bootloader to first sector
	dd if=$(BOOTLOADER_BIN) of=$(OS_IMAGE) bs=512 count=1 conv=notrunc
	# Mount and copy kernel (requires loop device support)
	# For Windows, we'll use a simpler approach
	@echo "Disk image created: $(OS_IMAGE)"

# Create ISO image using GRUB
iso: kernel $(BUILD_DIR)
	@echo "Creating ISO image..."
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL_BIN) $(ISO_DIR)/boot/kernel.bin
	echo 'menuentry "nekkoOS" {' > $(ISO_DIR)/boot/grub/grub.cfg
	echo '    multiboot /boot/kernel.bin' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '}' >> $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(OS_ISO) $(ISO_DIR)
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
	rm -rf $(BUILD_DIR)
	$(MAKE) -C $(BOOTLOADER_DIR) clean
	$(MAKE) -C $(KERNEL_DIR) clean
	$(MAKE) -C $(USERSPACE_DIR) clean
	@echo "Clean complete."

# Check toolchain
check-toolchain:
	@echo "Checking toolchain..."
	@which $(CC) > /dev/null || (echo "Error: $(CC) not found in PATH" && exit 1)
	@which $(AS) > /dev/null || (echo "Error: $(AS) not found in PATH" && exit 1)
	@which $(LD) > /dev/null || (echo "Error: $(LD) not found in PATH" && exit 1)
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
