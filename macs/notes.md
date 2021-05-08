
## Generating a new macOS disk image

This is less practiced since it is only done rarely. These steps will
likely require changes every time, as the OS upgrades happen.

The following are just notes I took during this process.

generate a disk image and clover image from
https://github.com/kholia/OSX-KVM/tree/master/HighSierra

I was at commit `3d995ed38ba72955c9355324ab92bd56d8bcf879` and
downloaded `CloverISO-4699.tar.lzma` from SourceForge with sha256sum
`d85ae93ef3aa3ef6e5b7074778cd3dbc2d74b4bdc5f6d4f6214ea213e0644602`
and my High Sierra ISO was `macos-high-sierra-10.13.6-cdr.iso`

I applied the following patch to OSX-KVM:

```diff
commit 223e3ebff7501219cf5ced8422ee2726a117a6aa
Author: Graham Christensen <graham@grahamc.com>
Date:   Mon Oct 8 20:09:44 2018 +0000

    NixOS patches

diff --git a/Clover.qcow2 b/Clover.qcow2
index 8527b16..51e049c 100644
Binary files a/Clover.qcow2 and b/Clover.qcow2 differ
diff --git a/HighSierra/clover-image.sh b/HighSierra/clover-image.sh
index 9300f7e..8dd1e32 100755
--- a/HighSierra/clover-image.sh
+++ b/HighSierra/clover-image.sh
@@ -1,4 +1,5 @@
-#!/bin/bash
+#!/usr/bin/env nix-shell
+#!nix-shell -i bash -p libguestfs

 # https://github.com/kraxel/imagefish

diff --git a/HighSierra/clover/config.plist.stripped.qemu b/HighSierra/clover/config.plist.stripped.qemu
index 79f7d7b..2159d89 100644
--- a/HighSierra/clover/config.plist.stripped.qemu
+++ b/HighSierra/clover/config.plist.stripped.qemu
@@ -7,7 +7,7 @@
 		<key>Arguments</key>
 		<string></string>
 		<key>DefaultVolume</key>
-		<string>clover</string>
+		<string>system</string>
 		<key>Log</key>
 		<true/>
 		<key>Secure</key>
diff --git a/boot-macOS-HS.sh b/boot-macOS-HS.sh
index 7e39eb8..b2f26d8 100755
--- a/boot-macOS-HS.sh
+++ b/boot-macOS-HS.sh
@@ -1,4 +1,5 @@
-#!/bin/bash
+#!/usr/bin/env nix-shell
+#!nix-shell -i bash -p qemu

 # See https://www.mail-archive.com/qemu-devel@nongnu.org/msg471657.html thread.
 #
@@ -15,7 +16,7 @@ MY_OPTIONS="+aes,+xsave,+avx,+xsaveopt,avx2,+smep"

 qemu-system-x86_64 -enable-kvm -m 3072 -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,$MY_OPTIONS\
 	  -machine pc-q35-2.9 \
-	  -smp 4,cores=2 \
+	  -smp cpus=8,cores=4,threads=2,sockets=1 -m 14336 \
 	  -usb -device usb-kbd -device usb-tablet \
 	  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
 	  -drive if=pflash,format=raw,readonly,file=OVMF_CODE.fd \
@@ -29,4 +30,6 @@ qemu-system-x86_64 -enable-kvm -m 3072 -cpu Penryn,kvm=on,vendor=GenuineIntel,+i
 	  -device ide-drive,bus=ide.0,drive=MacDVD \
 	  -drive id=MacDVD,if=none,snapshot=on,media=cdrom,file=./'HighSierra-10.13.6.iso' \
 	  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
-	  -monitor stdio
+	  -monitor stdio \
+	  -vnc 127.0.0.1:0
+
```

plus the patch

```diff
commit cee4519beb23a015f39116e178b3e0f642df6ed2
Author: Graham Christensen <graham@grahamc.com>
Date:   Mon Oct 8 22:08:51 2018 +0000

    provision / ephemeral

diff --git a/boot-macOS-HS-ephemeral.sh b/boot-macOS-HS-ephemeral.sh
new file mode 100755
index 0000000..1101977
--- /dev/null
+++ b/boot-macOS-HS-ephemeral.sh
@@ -0,0 +1,35 @@
+#!/usr/bin/env nix-shell
+#!nix-shell -i bash -p qemu
+
+# See https://www.mail-archive.com/qemu-devel@nongnu.org/msg471657.html thread.
+#
+# The "pc-q35-2.4" machine type was changed to "pc-q35-2.9" on 06-August-2017.
+#
+# The "media=cdrom" part is needed to make Clover recognize the bootable ISO
+# image.
+
+##################################################################################
+# NOTE: Comment out the "MY_OPTIONS" line in case you are having booting problems!
+##################################################################################
+
+MY_OPTIONS="+aes,+xsave,+avx,+xsaveopt,avx2,+smep"
+
+qemu-system-x86_64 -enable-kvm -m 3072 -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,$MY_OPTIONS\
+	  -machine pc-q35-2.9 \
+	  -smp cpus=8,cores=4,threads=2,sockets=1 -m 14336 \
+	  -usb -device usb-kbd -device usb-tablet \
+	  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
+	  -drive if=pflash,format=raw,readonly,file=OVMF_CODE.fd \
+	  -drive if=pflash,format=raw,file=OVMF_VARS-1024x768.fd \
+	  -smbios type=2 \
+          -snapshot \
+	  -device ich9-intel-hda -device hda-duplex \
+	  -device ide-drive,bus=ide.2,drive=Clover \
+	  -drive id=Clover,if=none,snapshot=on,format=qcow2,file=./'Clover.qcow2' \
+	  -device ide-drive,bus=ide.1,drive=MacHDD \
+	  -drive id=MacHDD,if=none,snapshot=on,file=./mac_hdd.img,format=qcow2 \
+	  -device ide-drive,bus=ide.0,drive=MacDVD \
+	  -drive id=MacDVD,if=none,snapshot=on,media=cdrom,file=./'HighSierra-10.13.6.iso' \
+	  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
+	  -vnc 127.0.0.1:0
+
diff --git a/boot-macOS-HS.sh b/boot-macOS-HS-provision.sh
similarity index 100%
rename from boot-macOS-HS.sh
rename to boot-macOS-HS-provision.sh
```

calculate your own `-smp` line like this:

 - cores: # of cores per socket
 - threads: # of threads per core, ie: hyperthreading? set to 2, none? set to 1
 - sockets: # of physical sockets in the system
 - cpus = * cores * threads * sockets


generate your own Clover.qcow2:

```
[nix-shell:~/OSX-KVM/HighSierra]# ./clover-image.sh --iso ./clover-ext/Clover-v2.4k-4699-X64.iso --cfg clover/config.plist.stripped.qemu --img Clover.qcow2
### copy files from iso
### creating and adding disk image
# disk-create Clover.qcow2 qcow2 256M
# add Clover.qcow2
# run
### partition disk image
# part-init /dev/sda gpt
# part-add /dev/sda p 2048 200000
# part-add /dev/sda p 202048 -2048
# part-set-gpt-type /dev/sda 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B
# part-set-bootable /dev/sda 1 true
# mkfs vfat /dev/sda1 label:EFI
# mkfs vfat /dev/sda2 label:clover
# mount /dev/sda2 /
# mkdir /ESP
# mount /dev/sda1 /ESP
### copy files to disk image
'clover/config.plist.stripped.qemu' -> '/run/user/0/clover-image.sh-2833/config.plist'
# mkdir /ESP/EFI
# mkdir /ESP/EFI/CLOVER
# copy-in /run/user/0/clover-image.sh-2833/EFI/BOOT /ESP/EFI
# copy-in /run/user/0/clover-image.sh-2833/EFI/CLOVER/CLOVERX64.efi /ESP/EFI/CLOVER
# copy-in /run/user/0/clover-image.sh-2833/EFI/CLOVER/drivers64UEFI /ESP/EFI/CLOVER
# copy-in /run/user/0/clover-image.sh-2833/EFI/CLOVER/drivers-Off/drivers64UEFI/PartitionDxe-64.efi /ESP/EFI/CLOVER/drivers64UEFI
# copy-in apfs.efi /ESP/EFI/CLOVER/drivers64UEFI
# copy-in /run/user/0/clover-image.sh-2833/EFI/CLOVER/tools /ESP/EFI/CLOVER
# copy-in /run/user/0/clover-image.sh-2833/config.plist /ESP/EFI/CLOVER
# -*- OsxAptioFix v3 -*-
# copy-in /run/user/0/clover-image.sh-2833/EFI/CLOVER/drivers-Off/drivers64UEFI/OsxAptioFix3Drv-64.efi /ESP/EFI/CLOVER/drivers64UEFI
# ls /ESP/EFI/CLOVER/drivers64UEFI
DataHubDxe-64.efi
FSInject-64.efi
OsxAptioFix3Drv-64.efi
PartitionDxe-64.efi
SMCHelper-64.efi
VBoxHfs-64.efi
apfs.efi
# umount-all
### cleaning up ...
```

[nix-shell:~/OSX-KVM/HighSierra]# cp Clover.qcow2 ../


then:

[root@nixos:~/OSX-KVM]# nix-shell -p qemu

[nix-shell:~/OSX-KVM]# qemu-img create -f qcow2 mac_hdd.img 128G
Formatting 'mac_hdd.img', fmt=qcow2 size=137438953472 cluster_size=65536 lazy_refcounts=off refcount_bits=16

then:

[root@nixos:~/OSX-KVM]# ./boot-macOS-HS.sh
QEMU 3.0.0 monitor - type 'help' for more information
(qemu)


then, use tigervnc's vncviewer. If you're running this on a remote
machine you can port-forward the VNC port via
`ssh -L 5900:localhost:5900 root@10.5.3.153`.

1. boot the install disk (only option)
2. select "English" langage
3. select "Disk Utility"
4. Find the "QEMU HARDDISK Media" disk which is about 130GB
5. click Erase, name: system (exactly `system`), format: Mac OS Extended (Journaled), scheme: GUID Partition Map, click Done
6. exit Disk Utility
7. select "Install macOS"
8. select "system" as the target disk
9. install will proceed and automatically reboot to the new root disk
and continue installation. this takes about 20-30 minutes.
10. Once the install process gets to the "Welcome" screen where you
select a physical location, Ctrl-C the QEMU process, copy the disk
image to another location for safe keeping. This duplicated image will
be used for future fresh re-setting-up like major upgrades:
`cp mac_hdd.img mac-hdd-1-installed-not-set-up.img` save this
somewhere for long-term storage.
11. re-run:

[root@nixos:~/OSX-KVM]# ./boot-macOS-HS-provision.sh
QEMU 3.0.0 monitor - type 'help' for more information
(qemu)
(qemu) usb_desc_get_descriptor: 2 unknown type 33 (len 10)
usb_desc_get_descriptor: 1 unknown type 33 (len 10)
qemu-system-x86_64: terminating on signal 2

[root@nixos:~/OSX-KVM]# cp mac_hdd.img mac-hdd-1-installed-not-set-up.img

[root@nixos:~/OSX-KVM]# ./boot-macOS-HS-provision.sh
QEMU 3.0.0 monitor - type 'help' for more information
(qemu)

and reconnect over vnc

12. Select "United States"
13. Select "US" Keyboard
14. When asked to sign in with an Apple ID, click "Set Up Later"
which is probably near the top
15. create a user:
       full name: nixos
    account name: nixos
        password: generate a new one each time, note: nixos is not a good password =)
            hint: set no hint
16. select "customize setup"
17. don't enable location services
18. select your timezone: UTC - United Kingdom
19. untick "share mac analytics" and "share crash data"
20. You'll get to the desktop and it'll try to config the keyboard,
press `z` then `/` then select `ANSI` and click Done
21. Click the magnifying glass in the top bar
22. Type "term" and press enter on Terminal
23. Run `sudo systemsetup -setremotelogin on` to turn on SSH. On Catalina,
    you may first need to go to the Apple menu > System Preferences >
    Security & Privacy > Privacy tab, choose "Full Disk Access" and add the
    "Terminal" application.
    IMPORTANT: DO NOT TEST SSH AT THIS STAGE!
Testing SSH now would cause the image to generate an SSH host key, and
cause it to be fixed in a generic disk image too soon.
24. Disable the protections preventing you from running unsigned
software: `sudo spctl --master-disable`
25. Enable automaticly mounting ISOs even before users log in,
    (should be one line):
    `sudo defaults write
     /Library/Preferences/SystemConfiguration/autodiskmount
     AutomountDisksWithoutUserLogin -bool YES`
26. Load the auto-run script, add the following to
    /Library/LaunchDaemons/org.nixos.bootup.plist:

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.nixos.bootup</string>
    <key>ProgramArguments</key>
    <array>
        <string>bash</string>
        <string>/Volumes/CONFIG/apply.sh</string>
    </array>
    <key>StandardOutPath</key>
    <string>/tmp/apply.stdout</string>
    <key>StandardErrorPath</key>
    <string>/tmp/apply.stderr</string>
    <key>RunAtLoad</key>
    <true/>
    <key>StartOnMount</key>
    <true/>
</dict>
</plist>

Copy-paste it, or if that doesn't work (it doesn't for me,) use a
pastebin. It is annoying to get this wrong, so be careful.

It might be here already:
https://gist.github.com/grahamc/126b1a28d50d99db315fb5b6fce551c7

27. Via the apple menu, select Shut Down
28. untick "Reopen windowsn when logging back in"
29. shut down
30. When the computer is shut down, duplicate mac_hd.img again:
`cp mac_hdd.img mac-hdd-2-initial-setup.img` and back this image up
as well. This image is used as the basis for ofborg and hydra
builders.

---

Specializing the image

Try to minimize specialization here

1. Run `./boot-macOS-HS-provision.sh`
2.

From now on, we'll be running ./boot-macOS-HS-ephemeral.sh which will
not write to mac_hdd.img. This means that the OS can update the disk
and even persist data across reboots, however all changes go away when
qemu restarts.

You can now SSH to the host running `./boot-macOS-HS-ephemeral.sh` via
`ssh -p 2200 nixos@10.5.3.153` for provisioning.


---

nixos module for running:


activation-time import:

1. create a zvol for the disk image based on the `import/hash-name` of the
   image file in the store

    [nix-shell:~]# zfs create -V $(qemu-img info ./OSX-KVM/mac-hdd-2-initial-setup.img --output=json | jq '."virtual-size"') rpool/imported-disk

2. qemu-img dd the data from the `.qcow2` to the zvol

    qemu-img dd if=./OSX-KVM/mac-hdd-2-initial-setup.img -f qcow2 of=/dev/zvol/rpool/imported-disk CoC-O raw bs=250000000

    ^ takes ~5min

3. snapshot zvol to `import/hash-name:import`

[nix-shell:~]# zfs snapshot rpool/imported-disk@import

[nix-shell:~]# zfs list -t snapshot
NAME                         USED  AVAIL  REFER  MOUNTPOINT
rpool/imported-disk@import     0B      -  14.5G  -




4. For each `import/*` see if their path is live, if not: delete the
   snapshot and zvol (via: `nix-store --query --roots /nix/store/hash-name`


run-time code:

pre-start: roll-back `execute/hash-name` to the snapshot for
           `import/hash-name:import`
           gene

           zfs rollback rpool/imported-disk@import

    start: execute qemu with the parameters like this:

<disk type='block' device='disk'>
  <driver name='qemu' type='raw' cache='none'/>
  <source dev='/dev/zd0'/>
  <target dev='vda' bus='virtio'/>
  <alias name='virtio-disk0'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
</disk>


sudo cp /Volumes/CONFIG/etc/ssh/ssh_host_* /etc/ssh/
sudo chown root:root /etc/ssh/ssh_host_*_key
sudo umount /Volumes/CONFIG


---

Sending a snapshot from macA to macB:

[nix-shell]$ nixops ssh mac3 -- -A

[root@mac3:~]# zfs send -cv rpool/mac-hdd-2-initial-setup-startup-script.img@pristine | ssh root@192.168.2.104 zfs recv -sv rpool/mac-hdd-2-initial-setup-startup-script.img
