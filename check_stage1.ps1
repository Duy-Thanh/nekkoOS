# Check Stage 1 binary for mini filesystem directory
Write-Host "Checking Stage 1 binary for mini filesystem..."

$stage1Path = "build\stage1.bin"

if (-not (Test-Path $stage1Path)) {
    Write-Host "Error: $stage1Path not found!" -ForegroundColor Red
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes($stage1Path)
Write-Host "Stage 1 size: $($bytes.Length) bytes"

# Check if it's exactly 512 bytes
if ($bytes.Length -ne 512) {
    Write-Host "Warning: Stage 1 should be exactly 512 bytes!" -ForegroundColor Yellow
}

# Check boot signature
$bootSig = [System.BitConverter]::ToUInt16($bytes, 510)
if ($bootSig -eq 0xAA55) {
    Write-Host "Boot signature: OK (0x55AA)" -ForegroundColor Green
} else {
    Write-Host "Boot signature: MISSING! Found 0x$($bootSig.ToString('X4'))" -ForegroundColor Red
}

# Check mini filesystem directory at offset 446
Write-Host "`nMini filesystem directory (at offset 446):"
Write-Host "=========================================="

for ($i = 0; $i -lt 4; $i++) {
    $offset = 446 + ($i * 16)
    
    # Get filename (8 bytes)
    $nameBytes = $bytes[$offset..($offset+7)]
    $name = [System.Text.Encoding]::ASCII.GetString($nameBytes).TrimEnd([char]0)
    
    # Get file type
    $type = $bytes[$offset + 8]
    
    # Get LBA (4 bytes, little endian)
    $lba = [System.BitConverter]::ToUInt32($bytes, $offset + 10)
    
    # Get sector count (2 bytes, little endian)
    $sectors = [System.BitConverter]::ToUInt16($bytes, $offset + 14)
    
    $typeStr = switch ($type) {
        0 { "UNUSED" }
        1 { "BOOTLOADER" }
        2 { "KERNEL" }
        default { "UNKNOWN($type)" }
    }
    
    Write-Host "Entry $i`: '$name' Type=$typeStr LBA=$lba Sectors=$sectors"
    
    if ($type -eq 0) {
        # Skip unused entries
        continue
    }
    
    # Check if this looks valid
    if ($name -eq "" -or $lba -eq 0) {
        Write-Host "  WARNING: Entry looks invalid!" -ForegroundColor Yellow
    }
}

# Check for some key strings that should be in Stage 1
$stage1Text = [System.Text.Encoding]::ASCII.GetString($bytes)

if ($stage1Text.Contains("STAGE2")) {
    Write-Host "`nFound STAGE2 reference in binary" -ForegroundColor Green
} else {
    Write-Host "`nNo STAGE2 reference found - mini filesystem may not be built in!" -ForegroundColor Red
}

if ($stage1Text.Contains("MiniFS") -or $stage1Text.Contains("miniFS")) {
    Write-Host "Found MiniFS reference in binary" -ForegroundColor Green
} else {
    Write-Host "No MiniFS reference found" -ForegroundColor Yellow
}

Write-Host "`nDone checking Stage 1 binary."