# check-phone.ps1 - run after read_tables.xml (manual install, step "Check the phone").
# Reads gpt_lun0.bin, gpt_lun4.bin and devinfo.bin from the folder you give it (default: this
# folder) and checks, without touching the phone:
#   1. every partition the kit writes is exactly where the XML files expect it
#   2. the bootloader is unlocked (devinfo, the bootloader's own record)
#   3. which slot (A or B) is active, so you know which rawprogram_*_slot_X.xml to use
# It stops at the first problem. If it says STOP, don't write anything.
param([string]$Dir = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
$SS = 4096

# lun, label, first sector, sectors (0 = size not checked)
$expected = @(
    @(4, "boot_a", 113318, 24576),
    @(4, "boot_b", 465632, 24576),
    @(4, "init_boot_a", 341414, 2048),
    @(4, "init_boot_b", 686048, 2048),
    @(4, "vendor_boot_a", 282982, 24576),
    @(4, "vendor_boot_b", 635296, 24576),
    @(4, "dtbo_a", 137962, 6144),
    @(4, "dtbo_b", 490276, 6144),
    @(4, "vbmeta_a", 137946, 16),
    @(4, "vbmeta_b", 490260, 16),
    @(0, "vbmeta_system_a", 4203272, 16),
    @(0, "vbmeta_system_b", 4203288, 16),
    @(4, "recovery_a", 315302, 25600),
    @(4, "recovery_b", 659936, 25600),
    @(0, "super", 8968, 4194304),
    @(0, "metadata", 4203304, 16384),
    @(4, "devinfo", 696954, 1),
    @(0, "userdata", 4350760, 0)
)

function Read-Gpt([string]$file, [int]$lun) {
    if (-not (Test-Path $file)) { throw "STOP: $file is missing. Run the read_tables.xml step first." }
    $b = [IO.File]::ReadAllBytes($file)
    if ([Text.Encoding]::ASCII.GetString($b, $SS, 8) -ne 'EFI PART') { throw "STOP: $file is not a partition table (no EFI PART header)." }
    $entLba = [BitConverter]::ToUInt64($b, $SS + 72)
    $n = [BitConverter]::ToUInt32($b, $SS + 80)
    $esz = [BitConverter]::ToUInt32($b, $SS + 84)
    $t = @{}
    for ($i = 0; $i -lt $n; $i++) {
        $o = [int]($entLba * $SS + $i * $esz)
        if ($o + 128 -gt $b.Length) { break }
        $first = [BitConverter]::ToUInt64($b, $o + 32)
        if ($first -eq 0) { continue }
        $last = [BitConverter]::ToUInt64($b, $o + 40)
        $attr = [BitConverter]::ToUInt64($b, $o + 48)
        $name = [Text.Encoding]::Unicode.GetString($b, $o + 56, 72).TrimEnd([char]0)
        $t[$name] = [pscustomobject]@{ Lun = $lun; First = $first; Sectors = $last - $first + 1; Attr = $attr }
    }
    return $t
}

$t = @{}
foreach ($lun in 0, 4) { (Read-Gpt (Join-Path $Dir "gpt_lun$lun.bin") $lun).GetEnumerator() | ForEach-Object { $t[$_.Key] = $_.Value } }

$bad = 0
foreach ($e in $expected) {
    $lun, $label, $first, $sectors = $e
    $p = $t[$label]
    if ($lun -ne 0 -and $lun -ne 4) { continue }
    if (-not $p) { Write-Host "  MISSING  $label" -ForegroundColor Red; $bad++; continue }
    if ($p.Lun -ne $lun -or $p.First -ne $first -or ($sectors -ne 0 -and $p.Sectors -ne $sectors)) {
        Write-Host "  DIFFERS  $label  (phone: LUN $($p.Lun) sector $($p.First), $($p.Sectors) sectors; kit: LUN $lun sector $first, $sectors sectors)" -ForegroundColor Red
        $bad++
    }
}
if ($bad) { throw "STOP: $bad partition(s) are not where this kit expects them. Don't use the XML files on this phone; use the installer app instead (it reads your phone's own table)." }
Write-Host "Partition layout: matches the kit" -ForegroundColor Green

$dv = Join-Path $Dir 'devinfo.bin'
if (-not (Test-Path $dv)) { throw "STOP: devinfo.bin is missing. Run the read_tables.xml step first." }
$d = [IO.File]::ReadAllBytes($dv)
if ([Text.Encoding]::ASCII.GetString($d, 0, 13) -ne 'ANDROID-BOOT!') { throw "STOP: devinfo.bin has no ANDROID-BOOT! header; the lock state can't be read." }
if ($d[13] -ne 1) { throw "STOP: the bootloader is LOCKED. Writing a custom ROM to a locked phone stops it from starting. Unlock it first." }
Write-Host "Bootloader: unlocked" -ForegroundColor Green

# active slot = GPT attribute bit 50 on boot_a / boot_b
$a = (($t['boot_a'].Attr -shr 50) -band 1) -eq 1
$b = (($t['boot_b'].Attr -shr 50) -band 1) -eq 1
if ($a -eq $b) { throw "STOP: can't tell the active slot (boot_a active=$a, boot_b active=$b)." }
$slot = if ($a) { 'a' } else { 'b' }
Write-Host "Active slot: $($slot.ToUpper())  -> use rawprogram_rom_slot_$slot.xml / rawprogram_twrp_slot_$slot.xml" -ForegroundColor Green
Write-Host "OK: safe to continue."
