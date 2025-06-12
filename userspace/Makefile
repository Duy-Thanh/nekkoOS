# Userspace Makefile
# Builds user applications and libraries for nekkoOS

# Toolchain
CC = i686-elf-gcc
AS = i686-elf-as
LD = i686-elf-ld
AR = i686-elf-ar
OBJCOPY = i686-elf-objcopy

# Directories
LIBC_DIR = libc
APPS_DIR = apps
BUILD_DIR = ../build
USERSPACE_BUILD = $(BUILD_DIR)/userspace

# Compiler flags
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -nostdlib -nostdinc
CFLAGS += -fno-builtin -fno-stack-protector -fno-pic -fno-pie
CFLAGS += -m32 -march=i686 -mtune=i686
CFLAGS += -I$(LIBC_DIR)/include

# Assembler flags
ASFLAGS = --32

# Linker flags
LDFLAGS = -m elf_i386 -nostdlib

# Libraries
LIBC_A = $(USERSPACE_BUILD)/libc.a

# Applications
APPS = $(USERSPACE_BUILD)/init $(USERSPACE_BUILD)/shell $(USERSPACE_BUILD)/hello

.PHONY: all clean libc apps init shell hello

# Default target
all: $(BUILD_DIR) libc apps

# Create build directories
$(BUILD_DIR):
	mkdir -p $(USERSPACE_BUILD)

# Build libc
libc: $(LIBC_A)

$(LIBC_A): $(BUILD_DIR)
	@echo "Building libc..."
	$(MAKE) -C $(LIBC_DIR) BUILD_DIR=../../$(USERSPACE_BUILD)
	@echo "libc built successfully!"

# Build all applications
apps: libc $(APPS)
	@echo "All applications built successfully!"

# Build init process
$(USERSPACE_BUILD)/init: $(APPS_DIR)/init.c $(LIBC_A)
	@echo "Building init..."
	$(CC) $(CFLAGS) -c $(APPS_DIR)/init.c -o $(USERSPACE_BUILD)/init.o
	$(LD) $(LDFLAGS) -T $(APPS_DIR)/user.ld -o $@ $(USERSPACE_BUILD)/init.o $(LIBC_A)

# Build shell
$(USERSPACE_BUILD)/shell: $(APPS_DIR)/shell.c $(LIBC_A)
	@echo "Building shell..."
	$(CC) $(CFLAGS) -c $(APPS_DIR)/shell.c -o $(USERSPACE_BUILD)/shell.o
	$(LD) $(LDFLAGS) -T $(APPS_DIR)/user.ld -o $@ $(USERSPACE_BUILD)/shell.o $(LIBC_A)

# Build hello world
$(USERSPACE_BUILD)/hello: $(APPS_DIR)/hello.c $(LIBC_A)
	@echo "Building hello..."
	$(CC) $(CFLAGS) -c $(APPS_DIR)/hello.c -o $(USERSPACE_BUILD)/hello.o
	$(LD) $(LDFLAGS) -T $(APPS_DIR)/user.ld -o $@ $(USERSPACE_BUILD)/hello.o $(LIBC_A)

# Individual targets
init: $(USERSPACE_BUILD)/init

shell: $(USERSPACE_BUILD)/shell

hello: $(USERSPACE_BUILD)/hello

# Clean build artifacts
clean:
	@echo "Cleaning userspace build artifacts..."
	rm -rf $(USERSPACE_BUILD)
	$(MAKE) -C $(LIBC_DIR) clean
	@echo "Userspace clean complete."

# Install applications to disk image (placeholder)
install:
	@echo "Installing userspace applications..."
	# TODO: Copy applications to disk image
	@echo "Install complete."

# Show userspace info
info:
	@echo "Userspace Build Information:"
	@echo "============================"
	@echo "CC:           $(CC)"
	@echo "CFLAGS:       $(CFLAGS)"
	@echo "LD:           $(LD)"
	@echo "LDFLAGS:      $(LDFLAGS)"
	@echo "LIBC_DIR:     $(LIBC_DIR)"
	@echo "APPS_DIR:     $(APPS_DIR)"
	@echo "BUILD_DIR:    $(USERSPACE_BUILD)"
	@echo "LIBC:         $(LIBC_A)"
	@echo "APPS:         $(APPS)"

# Check toolchain
check:
	@echo "Checking userspace build toolchain..."
	@which $(CC) > /dev/null || (echo "Error: $(CC) not found" && exit 1)
	@which $(AS) > /dev/null || (echo "Error: $(AS) not found" && exit 1)
	@which $(LD) > /dev/null || (echo "Error: $(LD) not found" && exit 1)
	@which $(AR) > /dev/null || (echo "Error: $(AR) not found" && exit 1)
	@echo "Toolchain check passed."
