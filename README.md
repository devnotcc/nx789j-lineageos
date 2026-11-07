# LineageOS 23.2 for the REDMAGIC 10 Pro / 10S Pro (NX789J)

Unofficial [LineageOS](https://lineageos.org) 23.2 (Android 16) build for the nubia REDMAGIC
10 Pro and 10S Pro (model **NX789J**), in two variants:

- **gapps**: with Google apps ([MindTheGapps](https://github.com/MindTheGapps))
- **vanilla**: no Google apps

Both come with the same KernelSU-Next + SUSFS kernel and **RedMagic Tools** (cooling fan, side
slider, performance modes, charge separation) as the
[Evolution X build](https://github.com/devnotcc/nx789j-evox).

> [!WARNING]
> **Not tested on a phone yet.** These builds are made from the same device tree, vendor blobs
> and kernel as the Evolution X build, which is in daily use, but no one has started LineageOS
> from these images yet. Have a backup and a way back (the installer app's backup, or a stock
> EDL package) before trying it, and please report how it went in the [issues](../../issues).

Screenshots will follow once it has been installed on a phone.

**Download:** [Releases](../../releases) (latest: **23.2-20261104.2**).

## What should work

Everything listed as working for the [Evolution X build](https://github.com/devnotcc/nx789j-evox#what-works)
uses the same device tree and should behave the same here, but none of it has been confirmed on
LineageOS. Not ported yet (same as Evolution X): the shoulder triggers and the RGB lighting.

## Install

You need an **unlocked bootloader** first. The free unlock for the 10 Pro is the
**ZTE Family Toolbox** (中兴家族工具箱) **1.2.8-beta4**, from
[this XDA thread](https://xdaforums.com/t/red-magic-11-pro-guide-bootloader-unlock-free-also-support-rm10-pad3pro-z70u-z80u-unlock-zte-family-toolbox.4780930/).
Don't update the stock firmware to 11.0.13 or later before unlocking: the thread reports that it
blocks the unlock.

Made for stock firmware **RedMagicOS 11.0.4** (baseband `...1.82720.133`). Firmware isn't replaced
by this ROM.

### Recommended: the installer app

The [NX789J Installer](https://github.com/devnotcc/nx789j-installer) checks the phone and the
bootloader unlock, backs up what it replaces, writes the images over EDL, reads them back and
checks the phone after it starts.

1. Set up the installer: see its [Getting started](https://github.com/devnotcc/nx789j-installer#getting-started).
2. Pick **LineageOS**, choose with or without Google apps, and follow the steps.

### Manual: EDL with the toolbox's tools

Step by step with `fh_loader`: **[MANUAL.md](MANUAL.md)**. Use the images of the variant you
want (`lineage-gapps-…` or `lineage-vanilla-…`).

## Source

- Device tree: [android_device_nubia_nx789j](https://github.com/devnotcc/android_device_nubia_nx789j)
- Vendor blobs (from RedMagicOS 11.0.4): [android_vendor_nubia_nx789j](https://github.com/devnotcc/android_vendor_nubia_nx789j)
- Kernel (GKI 6.6.92 + KernelSU-Next + SUSFS): [android_kernel_nubia_nx789j](https://github.com/devnotcc/android_kernel_nubia_nx789j)

## Credits

The [LineageOS](https://github.com/LineageOS) team, [MindTheGapps](https://github.com/MindTheGapps),
[KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) and SUSFS, and @SYXZ (某贼) for
the ZTE Family Toolbox and the bootloader unlock.
