# nekkoOS Build Script for Windows
# PowerShell build automation for the 32-bit operating system

param(
    [string]$Target = "all",
    [switch]$Clean,
    [switch]$Verbose,
    [switch]$Help
)

# Script configuration
$ErrorActionPreference = "Stop"
$BuildDir = "build"
$LogFile = "build.log"

# Tool paths (adjust these to match your installation)
$Tools = @{
    CC = "i686-elf-gcc.exe"
    AS = "i686-elf-as.exe"
    LD = "i686-elf-ld.exe"
    OBJCOPY = "i686-elf-objcopy.exe"
    OBJDUMP = "i686-elf-objdump.exe"
    NASM = "nasm.exe"
    QEMU = "qemu-system-i386.exe"
}

# Color output functions
function Write-Success($Message) {
    Write-Host $Message -ForegroundColor Green
}

function Write-Error($Message) {
    Write-Host $Message -ForegroundColor Red
}

function Write-Warning($Message) {
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Info($Message) {
    Write-Host $Message -ForegroundColor Cyan
}

# Help function
function Show-Help {
    Write-Host "nekkoOS Build Script" -ForegroundColor Yellow
    Write-Host "===================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage: .\build.ps1 [options] [target]" -ForegroundColor White
    Write-Host ""
    Write-Host "Targets:" -ForegroundColor White
    Write-Host "  all        - Build everything (default)"
    Write-Host "  bootloader - Build bootloader only"
    Write-Host "  kernel     - Build kernel only"
    Write-Host "  userspace  - Build userspace only"
    Write-Host "  image      - Create disk image"
    Write-Host "  run        - Build and run in QEMU"
    Write-Host "  debug      - Build and run with GDB support"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Clean     - Clean build artifacts"
    Write-Host "  -Verbose   - Enable verbose output"
    Write-Host "  -Help      - Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\build.ps1                    # Build everything"
    Write-Host "  .\build.ps1 -Clean             # Clean all"
    Write-Host "  .\build.ps1 kernel             # Build kernel only"
    Write-Host "  .\build.ps1 run                # Build and run"
    Write-Host "  .\build.ps1 -Clean -Verbose    # Clean with verbose output"
}

# Check if tools are available
function Test-Toolchain {
    Write-Info "Checking toolchain..."

    $missing = @()
    foreach ($tool in $Tools.Keys) {
        $command = $Tools[$tool]
        try {
            $null = Get-Command $command -ErrorAction Stop
            if ($Verbose) {
                Write-Host "  ✓ $command found" -ForegroundColor Green
            }
        }
        catch {
            $missing += $command
            Write-Host "  ✗ $command not found" -ForegroundColor Red
        }
    }

    if ($missing.Count -gt 0) {
        Write-Error "Missing tools: $($missing -join ', ')"
        Write-Warning "Please install i686-elf-tools and ensure they are in your PATH"
        Write-Warning "Download from: https://github.com/lordmilko/i686-elf-tools"
        exit 1
    }

    Write-Success "Toolchain check passed!"
}

# Create build directory
function New-BuildDirectory {
    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
        Write-Info "Created build directory: $BuildDir"
    }
}

# Clean build artifacts
function Invoke-Clean {
    Write-Info "Cleaning build artifacts..."

    if (Test-Path $BuildDir) {
        Remove-Item -Recurse -Force $BuildDir
        Write-Success "Removed build directory"
    }

    # Clean object files
    Get-ChildItem -Recurse -Filter "*.o" | Remove-Item -Force
    Write-Success "Removed object files"

    # Clean logs
    if (Test-Path $LogFile) {
        Remove-Item $LogFile
        Write-Success "Removed log file"
    }

    Write-Success "Clean complete!"
}

# Execute command with logging
function Invoke-BuildCommand($Command, $Arguments = @()) {
    $fullCommand = "$Command $($Arguments -join ' ')"

    if ($Verbose) {
        Write-Host "Executing: $fullCommand" -ForegroundColor Gray
    }

    # Log command
    Add-Content -Path $LogFile -Value "$(Get-Date): $fullCommand"

    try {
        $output = & $Command @Arguments 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Command failed with exit code $LASTEXITCODE"
            Write-Error "Command: $fullCommand"
            if ($output) {
                Write-Error "Output: $output"
            }
            exit $LASTEXITCODE
        }

        if ($Verbose -and $output) {
            Write-Host $output -ForegroundColor Gray
        }

        # Log output
        if ($output) {
            Add-Content -Path $LogFile -Value $output
        }

    } catch {
        Write-Error "Failed to execute: $fullCommand"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Build bootloader
function Build-Bootloader {
    Write-Info "Building bootloader..."

    Push-Location "bootloader"
    try {
        # Build using make
        Invoke-BuildCommand "make" @("BUILD_DIR=../$BuildDir")
        Write-Success "Bootloader built successfully!"
    }
    finally {
        Pop-Location
    }
}

# Build kernel
function Build-Kernel {
    Write-Info "Building kernel..."

    Push-Location "kernel"
    try {
        # Build using make
        Invoke-BuildCommand "make" @("BUILD_DIR=../$BuildDir")
        Write-Success "Kernel built successfully!"
    }
    finally {
        Pop-Location
    }
}

# Build userspace
function Build-Userspace {
    Write-Info "Building userspace..."

    Push-Location "userspace"
    try {
        # Build using make
        Invoke-BuildCommand "make" @("BUILD_DIR=../$BuildDir")
        Write-Success "Userspace built successfully!"
    }
    finally {
        Pop-Location
    }
}

# Create disk image
function New-DiskImage {
    Write-Info "Creating disk image..."

    $imagePath = "$BuildDir/nekkoOS.img"
    $bootloaderPath = "$BuildDir/bootloader.bin"

    # Create empty 32MB disk image
    $bytes = New-Object byte[] (32 * 1024 * 1024)
    [System.IO.File]::WriteAllBytes($imagePath, $bytes)

    # Write bootloader to first sector
    if (Test-Path $bootloaderPath) {
        $bootloader = [System.IO.File]::ReadAllBytes($bootloaderPath)
        $image = [System.IO.File]::ReadAllBytes($imagePath)

        # Copy bootloader to first 512 bytes
        for ($i = 0; $i -lt [Math]::Min($bootloader.Length, 512); $i++) {
            $image[$i] = $bootloader[$i]
        }

        [System.IO.File]::WriteAllBytes($imagePath, $image)
        Write-Success "Disk image created: $imagePath"
    } else {
        Write-Error "Bootloader not found: $bootloaderPath"
        exit 1
    }
}

# Run in QEMU
function Start-QEMU($DebugMode = $false) {
    $imagePath = "$BuildDir/nekkoOS.img"

    if (-not (Test-Path $imagePath)) {
        Write-Error "Disk image not found: $imagePath"
        Write-Info "Run 'build.ps1 image' first to create the image"
        exit 1
    }

    Write-Info "Starting nekkoOS in QEMU..."

    $qemuArgs = @(
        "-m", "32M"
        "-serial", "stdio"
        "-drive", "file=$imagePath,format=raw"
    )

    if ($DebugMode) {
        $qemuArgs += @("-s", "-S")
        Write-Info "QEMU started with GDB support"
        Write-Info "Connect GDB with: target remote localhost:1234"
    }

    try {
        Invoke-BuildCommand $Tools.QEMU $qemuArgs
    } catch {
        Write-Warning "QEMU execution interrupted"
    }
}

# Show build configuration
function Show-Configuration {
    Write-Info "Build Configuration:"
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "Build Directory: $BuildDir"
    Write-Host "Log File: $LogFile"
    Write-Host "Target: $Target"
    Write-Host "Verbose: $Verbose"
    Write-Host ""

    Write-Host "Tools:" -ForegroundColor Cyan
    foreach ($tool in $Tools.Keys) {
        Write-Host "  $tool`: $($Tools[$tool])"
    }
    Write-Host ""
}

# Main build function
function Invoke-Build {
    switch ($Target.ToLower()) {
        "all" {
            New-BuildDirectory
            Build-Bootloader
            Build-Kernel
            Build-Userspace
            New-DiskImage
            Write-Success "Build complete!"
        }
        "bootloader" {
            New-BuildDirectory
            Build-Bootloader
        }
        "kernel" {
            New-BuildDirectory
            Build-Kernel
        }
        "userspace" {
            New-BuildDirectory
            Build-Userspace
        }
        "image" {
            New-BuildDirectory
            New-DiskImage
        }
        "run" {
            if (-not (Test-Path "$BuildDir/nekkoOS.img")) {
                Invoke-Build "all"
            }
            Start-QEMU
        }
        "debug" {
            if (-not (Test-Path "$BuildDir/nekkoOS.img")) {
                Invoke-Build "all"
            }
            Start-QEMU -DebugMode $true
        }
        default {
            Write-Error "Unknown target: $Target"
            Show-Help
            exit 1
        }
    }
}

# Main script execution
try {
    # Initialize log file
    "nekkoOS Build Log - $(Get-Date)" | Out-File -FilePath $LogFile

    Write-Host "nekkoOS Build System" -ForegroundColor Yellow
    Write-Host "===================" -ForegroundColor Yellow
    Write-Host ""

    if ($Help) {
        Show-Help
        exit 0
    }

    if ($Verbose) {
        Show-Configuration
    }

    if ($Clean) {
        Invoke-Clean
        if ($Target -eq "all" -and -not $PSBoundParameters.ContainsKey('Target')) {
            exit 0
        }
    }

    Test-Toolchain
    Invoke-Build

} catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    Write-Error "Check $LogFile for details"
    exit 1
}
