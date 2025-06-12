# libc Makefile
# Builds the standard C library for nekkoOS userspace

# Toolchain
CC = i686-elf-gcc
AS = i686-elf-as
AR = i686-elf-ar
RANLIB = i686-elf-ranlib

# Directories
INCLUDE_DIR = include
SRC_DIR = .
BUILD_DIR = ../../build/userspace

# Compiler flags
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -nostdlib -nostdinc
CFLAGS += -fno-builtin -fno-stack-protector -fno-pic -fno-pie
CFLAGS += -m32 -march=i686 -mtune=i686
CFLAGS += -I$(INCLUDE_DIR)

# Assembler flags
ASFLAGS = --32

# Source files
C_SOURCES = string.c stdio.c stdlib.c ctype.c syscall.c
ASM_SOURCES = start.s

# Object files
C_OBJECTS = $(C_SOURCES:.c=.o)
ASM_OBJECTS = $(ASM_SOURCES:.s=.o)
OBJECTS = $(C_OBJECTS) $(ASM_OBJECTS)

# Output library
LIBC_A = $(BUILD_DIR)/libc.a

.PHONY: all clean install

# Default target
all: $(LIBC_A)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build libc archive
$(LIBC_A): $(OBJECTS) $(BUILD_DIR)
	@echo "Creating libc archive..."
	$(AR) rcs $(LIBC_A) $(OBJECTS)
	$(RANLIB) $(LIBC_A)
	@echo "libc.a created: $(LIBC_A)"

# Compile C source files
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble assembly source files
%.o: %.s
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) $< -o $@

# Install headers
install: $(BUILD_DIR)
	@echo "Installing libc headers..."
	cp -r $(INCLUDE_DIR)/* $(BUILD_DIR)/
	@echo "Headers installed to $(BUILD_DIR)/"

# Clean build artifacts
clean:
	@echo "Cleaning libc build artifacts..."
	rm -f $(OBJECTS) $(LIBC_A)
	@echo "libc clean complete."

# Show libc info
info:
	@echo "libc Build Information:"
	@echo "======================"
	@echo "CC:           $(CC)"
	@echo "CFLAGS:       $(CFLAGS)"
	@echo "AR:           $(AR)"
	@echo "C_SOURCES:    $(C_SOURCES)"
	@echo "ASM_SOURCES:  $(ASM_SOURCES)"
	@echo "OBJECTS:      $(OBJECTS)"
	@echo "OUTPUT:       $(LIBC_A)"

# Check dependencies
check:
	@echo "Checking libc build dependencies..."
	@which $(CC) > /dev/null || (echo "Error: $(CC) not found" && exit 1)
	@which $(AS) > /dev/null || (echo "Error: $(AS) not found" && exit 1)
	@which $(AR) > /dev/null || (echo "Error: $(AR) not found" && exit 1)
	@echo "Dependencies check passed."
