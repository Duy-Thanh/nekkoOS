#!/usr/bin/env python3
"""
nekkoOS FAT12 Disk Image Creator
Creates a proper FAT12 filesystem with bootloader and files
"""

import os
import struct
import sys
from datetime import datetime

class FAT12Builder:
    def __init__(self, image_size=1474560):  # 1.44MB floppy size
        self.image_size = image_size
        self.bytes_per_sector = 512
        self.sectors_per_cluster = 1
        self.reserved_sectors = 1
        self.fat_copies = 2
        self.root_entries = 224
        self.sectors_per_fat = 9
        self.sectors_per_track = 18
        self.heads = 2
        self.media_descriptor = 0xF0
        
        # Calculate filesystem layout
        self.total_sectors = image_size // self.bytes_per_sector
        self.fat_start = self.reserved_sectors
        self.root_start = self.fat_start + (self.fat_copies * self.sectors_per_fat)
        self.root_sectors = (self.root_entries * 32 + self.bytes_per_sector - 1) // self.bytes_per_sector
        self.data_start = self.root_start + self.root_sectors
        
        # Initialize disk image
        self.image = bytearray(image_size)
        
        # FAT table (12-bit entries)
        self.fat = [0] * ((self.sectors_per_fat * self.bytes_per_sector * 2) // 3)
        self.fat[0] = 0xFF0  # Media descriptor in FAT
        self.fat[1] = 0xFFF  # End of chain marker
        
        # Root directory entries
        self.root_entries_data = []
        
        # Next available cluster
        self.next_cluster = 2
        
    def create_boot_sector(self, boot_code):
        """Create FAT12 boot sector with bootloader code"""
        # Start with boot code
        boot_sector = bytearray(boot_code)
        
        # Ensure boot sector is exactly 512 bytes
        if len(boot_sector) > 512:
            raise ValueError("Boot code too large for boot sector")
        boot_sector.extend([0] * (512 - len(boot_sector)))
        
        # Write FAT12 BPB (BIOS Parameter Block) starting at offset 3
        bpb = struct.pack('<8sHBHBHHBHHHLLBBBL11s8s',
            b'NEKKOOS ',              # OEM identifier (8 bytes)
            self.bytes_per_sector,     # Bytes per sector
            self.sectors_per_cluster,  # Sectors per cluster
            self.reserved_sectors,     # Reserved sectors
            self.fat_copies,           # Number of FATs
            self.root_entries,         # Root directory entries
            self.total_sectors if self.total_sectors < 65536 else 0,  # Total sectors
            self.media_descriptor,     # Media descriptor
            self.sectors_per_fat,      # Sectors per FAT
            self.sectors_per_track,    # Sectors per track
            self.heads,                # Number of heads
            0,                         # Hidden sectors
            self.total_sectors if self.total_sectors >= 65536 else 0,  # Large sector count
            0,                         # Drive number (filled by BIOS)
            0,                         # Reserved
            0x29,                      # Extended boot signature
            0x12345678,                # Volume serial number
            b'nekkoOS    ',            # Volume label (11 bytes)
            b'FAT12   '                # Filesystem type (8 bytes)
        )
        
        # Insert BPB into boot sector (skip JMP and NOP at start)
        boot_sector[3:3+len(bpb)] = bpb
        
        # Ensure boot signature
        boot_sector[510:512] = b'\x55\xAA'
        
        return boot_sector
    
    def add_file(self, filename, data):
        """Add a file to the FAT12 filesystem"""
        # Convert filename to 8.3 format
        name_83 = self.convert_to_83(filename)
        
        # Calculate number of clusters needed
        clusters_needed = (len(data) + (self.sectors_per_cluster * self.bytes_per_sector) - 1) // (self.sectors_per_cluster * self.bytes_per_sector)
        
        if clusters_needed == 0:
            clusters_needed = 1
            
        # Allocate clusters
        first_cluster = self.next_cluster
        current_cluster = first_cluster
        
        for i in range(clusters_needed):
            if i == clusters_needed - 1:
                # Last cluster
                self.fat[current_cluster] = 0xFFF  # End of chain
            else:
                # Point to next cluster
                self.fat[current_cluster] = current_cluster + 1
                current_cluster += 1
        
        self.next_cluster += clusters_needed
        
        # Create directory entry
        entry = self.create_dir_entry(name_83, len(data), first_cluster)
        self.root_entries_data.append(entry)
        
        # Write file data to clusters
        offset = 0
        current_cluster = first_cluster
        
        while offset < len(data):
            # Calculate sector for this cluster
            sector = self.data_start + (current_cluster - 2) * self.sectors_per_cluster
            sector_offset = sector * self.bytes_per_sector
            
            # Write data to this cluster
            chunk_size = min(self.sectors_per_cluster * self.bytes_per_sector, len(data) - offset)
            self.image[sector_offset:sector_offset + chunk_size] = data[offset:offset + chunk_size]
            
            offset += chunk_size
            
            # Get next cluster
            if self.fat[current_cluster] == 0xFFF:
                break
            current_cluster = self.fat[current_cluster]
    
    def convert_to_83(self, filename):
        """Convert filename to 8.3 format"""
        if '.' in filename:
            name, ext = filename.upper().split('.', 1)
        else:
            name = filename.upper()
            ext = ''
        
        # Pad or truncate name to 8 characters
        name = name[:8].ljust(8)
        # Pad or truncate extension to 3 characters
        ext = ext[:3].ljust(3)
        
        return name + ext
    
    def create_dir_entry(self, name_83, file_size, first_cluster):
        """Create a directory entry"""
        now = datetime.now()
        
        # Date format: bits 15-9 = year-1980, bits 8-5 = month, bits 4-0 = day
        date = ((now.year - 1980) << 9) | (now.month << 5) | now.day
        
        # Time format: bits 15-11 = hours, bits 10-5 = minutes, bits 4-0 = seconds/2
        time = (now.hour << 11) | (now.minute << 5) | (now.second // 2)
        
        return struct.pack('<11sBBBHHHHHHHL',
            name_83.encode('ascii'),   # Filename (11 bytes)
            0x20,                      # Attributes (archive)
            0,                         # Reserved
            0,                         # Creation time fine resolution
            time,                      # Creation time
            date,                      # Creation date
            date,                      # Last access date
            0,                         # First cluster high (FAT32)
            time,                      # Last write time
            date,                      # Last write date
            first_cluster,             # First cluster low
            file_size                  # File size
        )
    
    def write_fat(self):
        """Write FAT tables to disk image"""
        # Convert 12-bit FAT entries to byte array
        fat_bytes = bytearray(self.sectors_per_fat * self.bytes_per_sector)
        
        for i in range(0, len(self.fat), 2):
            if i + 1 < len(self.fat):
                # Pack two 12-bit values into 3 bytes
                val1 = self.fat[i] & 0xFFF
                val2 = self.fat[i + 1] & 0xFFF
                
                # Convert to 3 bytes
                byte_offset = (i * 3) // 2
                if byte_offset + 2 < len(fat_bytes):
                    fat_bytes[byte_offset] = val1 & 0xFF
                    fat_bytes[byte_offset + 1] = ((val1 >> 8) & 0x0F) | ((val2 & 0x0F) << 4)
                    fat_bytes[byte_offset + 2] = (val2 >> 4) & 0xFF
        
        # Write both FAT copies
        for fat_copy in range(self.fat_copies):
            start_sector = self.fat_start + (fat_copy * self.sectors_per_fat)
            start_offset = start_sector * self.bytes_per_sector
            self.image[start_offset:start_offset + len(fat_bytes)] = fat_bytes
    
    def write_root_directory(self):
        """Write root directory to disk image"""
        root_data = bytearray(self.root_sectors * self.bytes_per_sector)
        
        # Write directory entries
        offset = 0
        for entry in self.root_entries_data:
            if offset + len(entry) <= len(root_data):
                root_data[offset:offset + len(entry)] = entry
                offset += len(entry)
        
        # Write to disk image
        start_offset = self.root_start * self.bytes_per_sector
        self.image[start_offset:start_offset + len(root_data)] = root_data
    
    def build(self, boot_sector_file, files, output_file):
        """Build the complete FAT12 disk image"""
        print(f"Building FAT12 disk image: {output_file}")
        
        # Read boot sector code
        try:
            with open(boot_sector_file, 'rb') as f:
                boot_code = f.read()
        except FileNotFoundError:
            print(f"Error: Boot sector file '{boot_sector_file}' not found")
            return False
        
        # Create boot sector with FAT12 BPB
        boot_sector = self.create_boot_sector(boot_code)
        self.image[0:512] = boot_sector
        
        print(f"Boot sector: {boot_sector_file} ({len(boot_code)} bytes)")
        
        # Add files
        for filename, filepath in files.items():
            try:
                with open(filepath, 'rb') as f:
                    file_data = f.read()
                self.add_file(filename, file_data)
                print(f"Added file: {filename} -> {filepath} ({len(file_data)} bytes)")
            except FileNotFoundError:
                print(f"Warning: File '{filepath}' not found, skipping")
        
        # Write FAT tables
        self.write_fat()
        
        # Write root directory
        self.write_root_directory()
        
        # Write disk image
        try:
            with open(output_file, 'wb') as f:
                f.write(self.image)
            print(f"FAT12 disk image created: {output_file}")
            
            # Print filesystem info
            print(f"\nFilesystem layout:")
            print(f"  Total sectors: {self.total_sectors}")
            print(f"  Bytes per sector: {self.bytes_per_sector}")
            print(f"  Reserved sectors: {self.reserved_sectors}")
            print(f"  FAT copies: {self.fat_copies}")
            print(f"  Sectors per FAT: {self.sectors_per_fat}")
            print(f"  Root directory entries: {self.root_entries}")
            print(f"  FAT start sector: {self.fat_start}")
            print(f"  Root start sector: {self.root_start}")
            print(f"  Data start sector: {self.data_start}")
            
            return True
            
        except Exception as e:
            print(f"Error writing disk image: {e}")
            return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python create_fat12.py <build_dir>")
        print("Creates nekkoOS.img with FAT12 filesystem")
        return 1
    
    build_dir = sys.argv[1]
    
    # File mappings: FAT12_name -> local_path
    files = {
        'STAGE2.BIN': os.path.join(build_dir, 'stage2.bin'),
        'KERNEL.BIN': os.path.join(build_dir, 'kernel.bin'),
    }
    
    # Build FAT12 image
    builder = FAT12Builder()
    
    boot_sector = os.path.join(build_dir, 'stage1.bin')
    output_image = os.path.join(build_dir, 'nekkoOS.img')
    
    success = builder.build(boot_sector, files, output_image)
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())