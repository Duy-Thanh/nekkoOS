# nekkoOS - 32-bit Operating System

A custom 32-bit operating system built from scratch, featuring a custom bootloader, kernel, and userspace with a proprietary executable format.

## Project Structure

```
nekkoOS/
├── bootloader/          # Stage 1 & 2 bootloader
├── kernel/              # 32-bit kernel implementation
├── userspace/           # User applications and libraries
├── executable-format/   # Custom executable format specification
├── tools/               # Build tools and utilities
└── docs/                # Documentation
```

## Components

### Bootloader
- **Stage 1**: Master Boot Record (MBR) bootloader
- **Stage 2**: Extended bootloader with filesystem support
- **Features**: A20 line enabling, protected mode setup, kernel loading

### Kernel
- **Architecture**: 32-bit x86 (i686)
- **Features**: 
  - Memory management (paging, heap allocation)
  - Process scheduling
  - Interrupt handling
  - Device drivers
  - System calls
  - Virtual File System (VFS)

### Userspace
- **System Libraries**: Core C library implementation
- **Shell**: Basic command-line interface
- **Applications**: System utilities and user programs
- **Runtime**: Support for custom executable format

### Custom Executable Format
- **Name**: NEF (Nekko Executable Format)
- **Features**: 
  - Optimized for 32-bit architecture
  - Built-in compression support
  - Security features
  - Dynamic linking capabilities

## Development Environment

### Prerequisites
- **Toolchain**: i686-elf-gcc, i686-elf-ld, i686-elf-objdump
- **Assembler**: NASM or GAS
- **Emulator**: QEMU (recommended) or VirtualBox
- **OS**: Windows with i686-elf-tools

### Build System
- **Primary**: Makefile-based build system
- **Secondary**: PowerShell build scripts for Windows

## Getting Started

1. **Setup Toolchain**
   ```bash
   # Ensure i686-elf-tools are in your PATH
   i686-elf-gcc --version
   ```

2. **Build Bootloader**
   ```bash
   cd bootloader
   make
   ```

3. **Build Kernel**
   ```bash
   cd kernel
   make
   ```

4. **Create OS Image**
   ```bash
   make image
   ```

5. **Run in Emulator**
   ```bash
   qemu-system-i386 -drive file=nekkoOS.img,format=raw
   ```

## Features (Planned)

- [x] Project structure setup
- [ ] Stage 1 bootloader (MBR)
- [ ] Stage 2 bootloader (extended)
- [ ] Kernel initialization
- [ ] Memory management
- [ ] Interrupt handling
- [ ] Process scheduling
- [ ] File system
- [ ] Device drivers
- [ ] System calls
- [ ] Custom executable format
- [ ] C library
- [ ] Shell implementation
- [ ] Basic applications

## Memory Layout

```
0x00000000 - 0x000003FF : Real Mode IVT
0x00000400 - 0x000004FF : BIOS Data Area
0x00000500 - 0x00007BFF : Bootloader Stack
0x00007C00 - 0x00007DFF : Stage 1 Bootloader
0x00007E00 - 0x0009FFFF : Available Memory
0x000A0000 - 0x000FFFFF : Video/BIOS ROM
0x00100000 - 0x???????? : Kernel + User Space
```

## Contributing

1. Follow the coding standards in `docs/CODING_STYLE.md`
2. Write tests for new features
3. Update documentation
4. Submit pull requests with clear descriptions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [OSDev Wiki](https://wiki.osdev.org/)
- [Intel 32-bit Architecture Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [Multiboot Specification](https://www.gnu.org/software/grub/manual/multiboot/)

## Contact

- **Project**: nekkoOS
- **Architecture**: 32-bit x86 (i686)
- **Status**: In Development