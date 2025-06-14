@echo off
rem nekkoOS Disk Image Creator
rem Creates a properly laid out disk image with mini filesystem

echo Creating nekkoOS disk image...

rem Clean up old image
if exist build\nekkoOS.img del build\nekkoOS.img

rem Create 32MB disk image
echo Creating 32MB disk image...
fsutil file createnew build\nekkoOS.img 33554432 >nul

rem Create temporary files for sectors
echo Creating sector layout...

rem Copy Stage 1 (512 bytes) to sector 0
copy /b build\stage1.bin build\sector0.tmp >nul

rem Pad Stage 1 to exactly 512 bytes if needed
powershell -Command "$file = Get-Content 'build\sector0.tmp' -Raw -Encoding Byte; if ($file.Length -lt 512) { $padded = New-Object byte[] 512; [Array]::Copy($file, 0, $padded, 0, $file.Length); [System.IO.File]::WriteAllBytes('build\sector0.tmp', $padded) }"

rem Copy Stage 2 (8192 bytes) starting at sector 1
copy /b build\stage2.bin build\sectors1-16.tmp >nul

rem Copy kernel starting at sector 17
copy /b build\kernel.bin build\sectors17plus.tmp >nul

rem Now assemble the final disk image
echo Assembling disk image...

rem Write sector 0 (Stage 1 with mini filesystem)
powershell -Command "$stage1 = [System.IO.File]::ReadAllBytes('build\sector0.tmp'); $image = [System.IO.File]::ReadAllBytes('build\nekkoOS.img'); [Array]::Copy($stage1, 0, $image, 0, 512); [System.IO.File]::WriteAllBytes('build\nekkoOS.img', $image)"

rem Write sectors 1-16 (Stage 2)
powershell -Command "$stage2 = [System.IO.File]::ReadAllBytes('build\sectors1-16.tmp'); $image = [System.IO.File]::ReadAllBytes('build\nekkoOS.img'); [Array]::Copy($stage2, 0, $image, 512, $stage2.Length); [System.IO.File]::WriteAllBytes('build\nekkoOS.img', $image)"

rem Write sectors 17+ (Kernel)
powershell -Command "$kernel = [System.IO.File]::ReadAllBytes('build\sectors17plus.tmp'); $image = [System.IO.File]::ReadAllBytes('build\nekkoOS.img'); [Array]::Copy($kernel, 0, $image, 8704, $kernel.Length); [System.IO.File]::WriteAllBytes('build\nekkoOS.img', $image)"

rem Clean up temporary files
del build\sector0.tmp >nul 2>&1
del build\sectors1-16.tmp >nul 2>&1
del build\sectors17plus.tmp >nul 2>&1

echo Disk image layout:
echo   Sector 0:     Stage 1 bootloader + mini filesystem (512 bytes)
echo   Sectors 1-16: Stage 2 bootloader (8192 bytes)
echo   Sectors 17+:  Kernel (%~z3 bytes)

echo nekkoOS disk image created successfully: build\nekkoOS.img