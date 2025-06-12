# nekkoOS Project Overview

## Introduction

nekkoOS is a custom 32-bit operating system built from scratch for the i386 (x86) architecture. This project demonstrates fundamental operating system concepts including bootloading, kernel development, memory management, and userspace programming. The OS features a custom executable format (NEF - Nekko Executable Format) designed specifically for optimal performance on 32-bit systems.

## Project Goals

- **Educational**: Learn low-level system programming and OS development
- **Custom Architecture**: Implement unique features not found in mainstream OSes
- **32-bit Focus**: Optimize specifically for i386 architecture
- **Modularity**: Clean separation between bootloader, kernel, and userspace
- **Standards Compliance**: Follow established conventions where appropriate

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        User Space                           │
├─────────────────┬─────────────────┬─────────────────────────┤
│     Shell       │  Applications   │      System Utils       │
├─────────────────┴─────────────────┴─────────────────────────┤
│                    libc (C Library)                         │
├─────────────────────────────────────────────────────────────┤
│                    System Calls                             │
├═════════════════════════════════════════════════════════════┤
│                       Kernel                                │
├─────────────────┬─────────────────┬─────────────────────────┤
│  Process Mgmt   │  Memory Mgmt    │    Device Drivers       │
├─────────────────┼─────────────────┼─────────────────────────┤
│   Scheduler     │     Paging      │    VGA/Keyboard/Timer   │
├─────────────────┼─────────────────┼─────────────────────────┤
│  Interrupts     │  Heap Allocator │       File System       │
├─────────────────┴─────────────────┴─────────────────────────┤
│              Hardware Abstraction Layer                     │
├═════════════════════════════════════════════════════════════┤
│                     Bootloader                              │
├─────────────────┬─────────────────────────────────────────────┤
│    Stage 1      │              Stage 2                      │
│   (MBR - 512B)  │        (Extended Loader)                  │
├─────────────────┴─────────────────────────────────────────────┤
│                      Hardware                               │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Bootloader (2 Stages)

**Stage 1 (Master Boot Record)**
- Size: 512 bytes (fits in MBR)
- Responsibilities:
  - Initialize basic hardware
  - Load Stage 2 from disk
  - Transition to Stage 2
- Features:
  - LBA and CHS disk addressing support
  - Error handling and diagnostics
  - Boot device detection

**Stage 2 (Extended Bootloader)**
- Size: Up to 16 sectors (8KB)
- Responsibilities:
  - Enable A20 line for >1MB memory access
  - Set up Global Descriptor Table (GDT)
  - Switch to 32-bit protected mode
  - Load kernel into memory
  - Transfer control to kernel
- Features:
  - Memory map detection (BIOS E820)
  - Advanced error handling
  - Kernel integrity verification

### 2. Kernel (32-bit Protected Mode)

**Core Subsystems:**

- **Memory Management**
  - Physical memory manager
  - Virtual memory (paging)
  - Heap allocator (kernel and user)
  - Memory protection

- **Process Management**
  - Process creation/termination
  - Context switching
  - Process scheduling (round-robin, priority-based)
  - Inter-process communication (IPC)

- **Interrupt Handling**
  - Interrupt Descriptor Table (IDT)
  - Hardware interrupt handlers
  - Software interrupts (system calls)
  - Exception handling

- **Device Drivers**
  - VGA text mode driver
  - Keyboard driver
  - Timer (PIT) driver
  - Storage device drivers

- **File System**
  - Virtual File System (VFS) layer
  - Simple file system implementation
  - Device file support (/dev)

### 3. Userspace

**System Libraries:**
- **libc**: Standard C library implementation
  - String manipulation functions
  - Memory allocation (malloc/free)
  - I/O functions
  - System call wrappers

**Applications:**
- **init**: First userspace process
- **shell**: Command-line interface
- **System utilities**: Basic UNIX-like tools

### 4. Custom Executable Format (NEF)

**Features:**
- Optimized for 32-bit architecture
- Built-in compression support
- Security features (checksums, permissions)
- Dynamic linking capabilities
- Efficient loading mechanism

## Development Environment

### Prerequisites

- **Operating System**: Windows (with WSL support optional)
- **Toolchain**: i686-elf cross-compiler toolchain
- **Assembler**: NASM (Netwide Assembler)
- **Emulator**: QEMU (recommended) or VirtualBox
- **Debugger**: GDB with i386 support
- **Build System**: Make + PowerShell scripts

### Directory Structure

```
nekkoOS/
├── bootloader/          # Bootloader components
│   ├── stage1/         # MBR bootloader (512 bytes)
│   └── stage2/         # Extended bootloader
├── kernel/             # Kernel implementation
│   ├── arch/           # Architecture-specific code
│   │   └── i386/       # x86 32-bit specific
│   ├── mm/             # Memory management
│   └── include/        # Kernel headers
├── userspace/          # User applications and libraries
│   ├── libc/           # C standard library
│   └── apps/           # User applications
├── executable-format/  # NEF format specification
├── tools/              # Build tools and utilities
├── docs/               # Documentation
└── build/              # Build output directory
```

## Memory Layout

### Physical Memory Map
```
0x00000000 - 0x000003FF : Real Mode Interrupt Vector Table
0x00000400 - 0x000004FF : BIOS Data Area
0x00000500 - 0x00007BFF : Available (bootloader stack)
0x00007C00 - 0x00007DFF : Stage 1 Bootloader (MBR)
0x00007E00 - 0x0009FFFF : Available conventional memory
0x000A0000 - 0x000BFFFF : Video memory
0x000C0000 - 0x000FFFFF : BIOS ROM
0x00100000 - 0xFFFFFFFF : Extended memory (kernel + user)
```

### Virtual Memory Layout (User Processes)
```
0x00000000 - 0x003FFFFF : User code (.text)
0x00400000 - 0x007FFFFF : User data (.data, .bss)
0x00800000 - 0xBFFFFFFF : User heap
0xC0000000 - 0xFFFFFFFF : Kernel space (mapped in all processes)
```

## Build System

### Make Targets

- `make all`: Build complete operating system
- `make bootloader`: Build bootloader only
- `make kernel`: Build kernel only
- `make userspace`: Build userspace components
- `make image`: Create bootable disk image
- `make run`: Build and run in QEMU
- `make debug`: Build and run with GDB support
- `make clean`: Clean all build artifacts

### PowerShell Script (Windows)

```powershell
.\build.ps1 all      # Build everything
.\build.ps1 run      # Build and run
.\build.ps1 debug    # Debug mode
.\build.ps1 -Clean   # Clean build
```

## Development Workflow

1. **Setup Environment**
   ```bash
   # Install i686-elf-tools
   # Install QEMU
   # Clone repository
   ```

2. **Build Project**
   ```bash
   make all
   ```

3. **Test in Emulator**
   ```bash
   make run
   ```

4. **Debug Issues**
   ```bash
   make debug
   # In another terminal:
   gdb build/kernel.elf
   (gdb) target remote localhost:1234
   ```

## Testing Strategy

### Unit Testing
- Individual component testing
- Mock hardware interfaces
- Automated test suite

### Integration Testing
- Bootloader → Kernel transition
- System call interface
- Driver functionality

### System Testing
- Full OS boot sequence
- Application execution
- Performance benchmarks

## Future Enhancements

### Short Term (v1.0)
- [ ] Complete basic kernel implementation
- [ ] Implement simple file system
- [ ] Basic shell with commands
- [ ] Memory protection

### Medium Term (v1.1)
- [ ] Network stack (TCP/IP)
- [ ] GUI subsystem
- [ ] More device drivers
- [ ] Process scheduling improvements

### Long Term (v2.0)
- [ ] SMP (multi-processor) support
- [ ] 64-bit architecture port
- [ ] Advanced security features
- [ ] Package management system

## Contributing

### Code Style
- Follow kernel coding standards
- Use consistent indentation (4 spaces)
- Document all public functions
- Include unit tests for new features

### Development Process
1. Create feature branch
2. Implement and test locally
3. Submit pull request
4. Code review
5. Merge to main branch

## Resources

### Documentation
- [Intel 32-bit Architecture Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [OSDev Wiki](https://wiki.osdev.org/)
- [Multiboot Specification](https://www.gnu.org/software/grub/manual/multiboot/)

### Tools
- [i686-elf-tools for Windows](https://github.com/lordmilko/i686-elf-tools)
- [QEMU Emulator](https://www.qemu.org/)
- [NASM Assembler](https://www.nasm.us/)

### Books
- "Operating System Concepts" by Silberschatz
- "Modern Operating Systems" by Tanenbaum
- "Operating Systems: Design and Implementation" by Tanenbaum

## License

This project is released under the MIT License. See LICENSE file for details.

---

**Project Status**: Active Development  
**Current Version**: 0.1-alpha  
**Target Architecture**: i386 (32-bit x86)  
**Last Updated**: 2024