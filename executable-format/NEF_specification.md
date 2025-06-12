# NEF (Nekko Executable Format) Specification v1.0

## Overview

The Nekko Executable Format (NEF) is a custom executable file format designed specifically for the nekkoOS 32-bit operating system. NEF provides efficient loading, security features, and optimized memory management for i386 architecture.

## Design Goals

- **Simplicity**: Easy to parse and load in kernel space
- **Efficiency**: Minimal overhead and fast loading
- **Security**: Built-in integrity checks and permissions
- **Flexibility**: Support for dynamic linking and shared libraries
- **Compression**: Optional built-in compression support

## File Structure

A NEF file consists of the following sections in order:

```
+------------------+
| NEF Header       | (64 bytes)
+------------------+
| Section Headers  | (32 bytes × section count)
+------------------+
| Section Data     | (variable size)
+------------------+
| Symbol Table     | (optional)
+------------------+
| String Table     | (optional)
+------------------+
| Relocation Table | (optional)
+------------------+
| Checksum         | (4 bytes)
+------------------+
```

## NEF Header

The NEF header is exactly 64 bytes and contains the following fields:

| Offset | Size | Field Name      | Description                           |
|--------|------|-----------------|---------------------------------------|
| 0x00   | 4    | magic           | Magic number: 0x4E454646 ("NEFF")    |
| 0x04   | 1    | version         | Format version (current: 1)           |
| 0x05   | 1    | type            | Executable type (see types below)     |
| 0x06   | 2    | flags           | File flags (see flags below)          |
| 0x08   | 4    | entry_point     | Virtual address of entry point        |
| 0x0C   | 4    | load_address    | Preferred load address                 |
| 0x10   | 4    | file_size       | Total file size in bytes              |
| 0x14   | 4    | memory_size     | Required memory size when loaded       |
| 0x18   | 2    | section_count   | Number of sections                     |
| 0x1A   | 2    | symbol_count    | Number of symbols                      |
| 0x1C   | 4    | symbol_offset   | Offset to symbol table                 |
| 0x20   | 4    | string_offset   | Offset to string table                 |
| 0x24   | 4    | reloc_offset    | Offset to relocation table             |
| 0x28   | 4    | checksum        | CRC32 checksum of file                 |
| 0x2C   | 16   | reserved        | Reserved for future use (must be 0)   |
| 0x3C   | 4    | timestamp       | Creation timestamp (Unix time)         |

### Executable Types

| Value | Type Name     | Description                    |
|-------|---------------|--------------------------------|
| 0x01  | EXEC          | Standalone executable          |
| 0x02  | DYN           | Dynamic library                |
| 0x03  | SYS           | System/kernel module           |
| 0x04  | DRIVER        | Device driver                  |

### File Flags

| Bit | Flag Name     | Description                         |
|-----|---------------|-------------------------------------|
| 0   | COMPRESSED    | File data is compressed             |
| 1   | RELOCATABLE   | Contains relocation information     |
| 2   | STRIPPED      | Debug symbols removed               |
| 3   | SIGNED        | File is digitally signed            |
| 4   | PIE           | Position Independent Executable     |
| 5-15| RESERVED      | Reserved for future use             |

## Section Header

Each section header is 32 bytes and describes a section of the executable:

| Offset | Size | Field Name      | Description                           |
|--------|------|-----------------|---------------------------------------|
| 0x00   | 4    | name_offset     | Offset into string table for name    |
| 0x04   | 4    | type            | Section type (see types below)        |
| 0x08   | 4    | flags           | Section flags (see flags below)       |
| 0x0C   | 4    | virtual_addr    | Virtual address in memory             |
| 0x10   | 4    | file_offset     | Offset in file                        |
| 0x14   | 4    | size            | Size of section                       |
| 0x18   | 4    | alignment       | Required alignment (power of 2)       |
| 0x1C   | 4    | reserved        | Reserved for future use               |

### Section Types

| Value | Type Name | Description                      |
|-------|-----------|----------------------------------|
| 0x00  | NULL      | Unused section                   |
| 0x01  | TEXT      | Executable code                  |
| 0x02  | DATA      | Initialized data                 |
| 0x03  | BSS       | Uninitialized data               |
| 0x04  | RODATA    | Read-only data                   |
| 0x05  | STACK     | Stack space                      |
| 0x06  | HEAP      | Heap space                       |
| 0x07  | DEBUG     | Debug information                |

### Section Flags

| Bit | Flag Name | Description                    |
|-----|-----------|--------------------------------|
| 0   | READ      | Section is readable            |
| 1   | WRITE     | Section is writable            |
| 2   | EXEC      | Section is executable          |
| 3   | COMPRESSED| Section data is compressed     |
| 4-31| RESERVED  | Reserved for future use        |

## Symbol Table Entry

Each symbol table entry is 16 bytes:

| Offset | Size | Field Name    | Description                     |
|--------|------|---------------|---------------------------------|
| 0x00   | 4    | name_offset   | Offset into string table       |
| 0x04   | 4    | value         | Symbol value/address            |
| 0x08   | 4    | size          | Symbol size                     |
| 0x0C   | 2    | section       | Section index                   |
| 0x0E   | 1    | type          | Symbol type                     |
| 0x0F   | 1    | binding       | Symbol binding                  |

### Symbol Types

| Value | Type Name | Description           |
|-------|-----------|-----------------------|
| 0x00  | NOTYPE    | Undefined type        |
| 0x01  | OBJECT    | Data object           |
| 0x02  | FUNC      | Function              |
| 0x03  | SECTION   | Section symbol        |

### Symbol Bindings

| Value | Binding   | Description           |
|-------|-----------|----------------------|
| 0x00  | LOCAL     | Local symbol         |
| 0x01  | GLOBAL    | Global symbol        |
| 0x02  | WEAK      | Weak symbol          |

## Relocation Entry

Each relocation entry is 12 bytes:

| Offset | Size | Field Name | Description                    |
|--------|------|------------|--------------------------------|
| 0x00   | 4    | offset     | Offset where to apply reloc    |
| 0x04   | 4    | symbol     | Symbol table index             |
| 0x08   | 4    | type       | Relocation type                |

### Relocation Types (i386)

| Value | Type Name   | Description                  |
|-------|-------------|------------------------------|
| 0x01  | R_386_32    | Direct 32-bit reference      |
| 0x02  | R_386_PC32  | PC-relative 32-bit reference |
| 0x03  | R_386_GOT32 | GOT entry reference          |
| 0x04  | R_386_PLT32 | PLT entry reference          |

## Loading Process

1. **Validation**: Verify magic number, version, and checksum
2. **Memory Allocation**: Allocate memory based on memory_size
3. **Section Loading**: Load each section to its virtual address
4. **Decompression**: Decompress compressed sections if needed
5. **Symbol Resolution**: Resolve external symbols
6. **Relocation**: Apply relocations to fix addresses
7. **Permission Setting**: Set appropriate memory permissions
8. **Entry Point**: Jump to entry_point address

## Compression Format

When the COMPRESSED flag is set, section data uses LZ4 compression:
- 4-byte uncompressed size
- LZ4-compressed data

## Security Features

- **Checksum**: CRC32 integrity check
- **Digital Signatures**: Optional RSA signatures
- **Stack Protection**: Non-executable stack enforcement
- **ASLR Support**: Address Space Layout Randomization

## Tools

The following tools are provided for NEF format:

- `nef-ld`: NEF linker
- `nef-objdump`: NEF file analyzer
- `nef-strip`: Symbol stripper
- `nef-compress`: Compression utility

## Example

```c
// Sample NEF header initialization
struct nef_header {
    uint32_t magic;         // 0x4E454646
    uint8_t version;        // 1
    uint8_t type;           // NEF_EXEC
    uint16_t flags;         // 0
    uint32_t entry_point;   // 0x401000
    uint32_t load_address;  // 0x400000
    uint32_t file_size;     // actual file size
    uint32_t memory_size;   // required memory
    uint16_t section_count; // number of sections
    uint16_t symbol_count;  // number of symbols
    // ... other fields
};
```

## Version History

- **v1.0**: Initial specification
  - Basic executable format
  - Section-based layout
  - Symbol and relocation support
  - Compression support

## Future Extensions

- **v1.1**: Planned features
  - Digital signature support
  - Enhanced compression algorithms
  - Plugin architecture support
  - 64-bit address extensions

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Author**: nekkoOS Development Team