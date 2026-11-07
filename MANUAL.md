# Manual install of LineageOS (without the installer app)

This writes LineageOS to the phone over EDL (Qualcomm 9008 mode) with the same Qualcomm tools the
installer uses, step by step. The installer app does all of this for you, with more checks
(it reads your phone's own partition table, backs up what it replaces and reads every partition
back). **Use the app unless you have a reason not to.**

> [!CAUTION]
> Writing the wrong file to the wrong place can leave the phone unable to start until it's
> restored over EDL. Follow the steps exactly, and stop if `check-phone.ps1` says STOP.

## What you need

- A **REDMAGIC 10 Pro or 10S Pro (NX789J)** with the **bootloader unlocked**.
- A Windows 10/11 PC and a USB-C data cable, connected straight to the PC (not through a hub).
- About 25 GB free on the PC.
- The **ZTE Family Toolbox** (中兴家族工具箱) **1.2.8-beta4**, the tool used to unlock the
  bootloader. It's linked in
  [this XDA thread](https://xdaforums.com/t/red-magic-11-pro-guide-bootloader-unlock-free-also-support-rm10-pad3pro-z70u-z80u-unlock-zte-family-toolbox.4780930/)
  (made by @SYXZ / 某贼, posted by AdaUnlocked). From it you use:
  - `bin\tool\Win\QSaharaServer.exe`, `fh_loader.exe`, `qcedlcmdhelper.exe`
  - the NX789J loader `bin\res\NX789J\devprg`
- The **Qualcomm 9008 driver**: the toolbox's `刷机驱动和运行库.txt` ("flashing driver and
  runtime") links to it. Once installed, the phone in EDL shows up in Device Manager as
  **Qualcomm HS-USB QDLoader 9008 (COMn)**.
- **zstd** to unpack the images: `zstd.exe` from
  [facebook/zstd releases](https://github.com/facebook/zstd/releases) (the `win64` zip).
- From this release: the image files (`*.zst.001`, …), `manifest.json` and
  `nx789j-manual-kit.zip`.

## 1. Unpack the images

Put everything from the release in one folder, for example `C:\nx789j\flash`, unzip
`nx789j-manual-kit.zip` into the same folder, and put `zstd.exe` there too. Then, in a
Command Prompt in that folder:

```bat
for %f in (*.zst.001) do copy /b "%~nf.0*" "%~nf"
for %f in (*.img.zst) do zstd -d "%f"
```

Check the unpacked images against `SHA256SUMS.txt` (PowerShell):

```powershell
Get-Content SHA256SUMS.txt | ForEach-Object { $h, $f = -split $_; if ((Get-FileHash $f).Hash -ne $h) { "BAD $f" } else { "ok  $f" } }
```

Every line must say `ok`. `super.img` is 16 GiB: that's right.

## 2. Put the phone in EDL mode

With the phone on and USB debugging allowed: `adb reboot edl`, or use the toolbox's own
"reboot to 9008" option. The screen stays **black** in EDL; that's normal. In Device Manager,
note the port number of **Qualcomm HS-USB QDLoader 9008 (COMn)**. Below, replace `COM5` with yours
and `C:\toolbox` with the folder you unpacked the toolbox to.

## 3. Load the EDL programmer

```bat
set T=C:\toolbox\bin\tool\Win
"%T%\QSaharaServer.exe" -p \\.\COM5 -s 13:C:\toolbox\bin\res\NX789J\devprg
"%T%\qcedlcmdhelper.exe" -p COM5 -m xml -f configure_zte.xml
```

## 4. Check the phone (reads only)

```bat
"%T%\fh_loader.exe" --port=\\.\COM5 --memoryname=ufs --search_path=. --sendxml=read_tables.xml --mainoutputdir=. --skip_config --noprompt
powershell -ExecutionPolicy Bypass -File check-phone.ps1
```

`check-phone.ps1` compares your phone's partition table with the one these XML files were made
from, checks that the bootloader is unlocked and tells you the **active slot**. Continue only if
it ends with `OK: safe to continue.` and note the slot (A or B).

## 5. Write LineageOS

For slot **A** (use `rawprogram_rom_slot_b.xml` if the check said B):

```bat
"%T%\fh_loader.exe" --port=\\.\COM5 --memoryname=ufs --search_path=. --sendxml=rawprogram_rom_slot_a.xml --mainoutputdir=. --skip_config --noprompt
```

This takes a few minutes (`super.img` is 16 GiB). It writes boot, init_boot, vendor_boot, dtbo,
vbmeta, vbmeta_system and super. Firmware (modem, bootloaders, TrustZone) is never touched.

**Coming from another OS** (stock RedMagicOS, Evolution X) **or want a clean start?** The data
partition has to be erased, or Android won't start. This **erases all apps, photos and files**:

```bat
fsutil file createnew zeros_64M.img 67108864
"%T%\fh_loader.exe" --port=\\.\COM5 --memoryname=ufs --search_path=. --sendxml=rawprogram_wipe_data.xml --mainoutputdir=. --skip_config --noprompt
```

Updating LineageOS over an older LineageOS build keeps your data: skip the wipe.

## 6. Restart

```bat
"%T%\fh_loader.exe" --port=\\.\COM5 --memoryname=ufs --search_path=. --sendxml=power_reset.xml --mainoutputdir=. --skip_config --noprompt
```

The first start after a wipe takes a few minutes.

## If something goes wrong

- **QSaharaServer fails** after an earlier attempt: the phone is still in EDL from last time and
  doesn't accept the loader again. Unplug it, hold **Power + Volume Up + Volume Down** for about
  20 seconds until it restarts, put it back in EDL and start again at step 3.
- **The phone only shows the bootloader / fastboot** after writing: see the installer app's
  **Device tools → Recovery and restart**, or ask in the issues.
- To go back to stock, flash a full stock EDL package with the toolbox.
