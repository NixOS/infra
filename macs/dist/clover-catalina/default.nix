{ lib
, runCommand
, fetchurl
, libguestfs
, libguestfs-appliance
, p7zip
, resolution ? "1024x768"
, csrFlag ? "0x3"
, params ? "-v"
, timeout ? "3"
# https://github.com/Clover-EFI-Bootloader/clover/blob/6b8018b1fec958d672951f87cefd8b6cfd5318ac/rEFIt_UEFI/Platform/boot.h#L127-L135
}:

lib.fix (self: {
  clover-image = runCommand "clover.qcow2" {
    buildInputs = [ libguestfs ];
    inherit resolution csrFlag params timeout;
    LIBGUESTFS_PATH = libguestfs-appliance;
  } ''
    export HOME=$NIX_BUILD_TOP
    mkdir work
    cp --no-preserve=mode ${self.clover-iso} clover.iso
    guestfish -a clover.iso -m "/dev/sda:/:norock" <<EOF
    copy-out /EFI work
    EOF
    eval $(guestfish --listen)
    guestfish --remote disk-create clover2.img qcow2 256M
    guestfish --remote add clover2.img
    time guestfish --remote run
    guestfish --remote part-init /dev/sda gpt
    guestfish --remote part-add /dev/sda p 2048 200000
    guestfish --remote -- part-add /dev/sda p 202048 -2048
    guestfish --remote part-set-gpt-type /dev/sda 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B
    guestfish --remote part-set-bootable /dev/sda 1 true
    guestfish --remote mkfs vfat /dev/sda1 label:EFI
    guestfish --remote mkfs vfat /dev/sda2 label:clover
    guestfish --remote mount /dev/sda2 /
    guestfish --remote mkdir /ESP
    guestfish --remote mount /dev/sda1 /ESP

    guestfish --remote mkdir /ESP/EFI
    guestfish --remote mkdir /ESP/EFI/CLOVER
    guestfish --remote mkdir /ESP/EFI/CLOVER/kexts
    guestfish --remote mkdir /ESP/EFI/CLOVER/kexts/Other
    guestfish --remote copy-in work/EFI/BOOT /ESP/EFI
    guestfish --remote copy-in work/EFI/CLOVER/CLOVERX64.efi /ESP/EFI/CLOVER

    guestfish --remote copy-in work/EFI/CLOVER/drivers /ESP/EFI/CLOVER
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/PartitionDxe.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/ApfsDriverLoader.efi /ESP/EFI/CLOVER/drivers/UEFI

    cp --no-preserve=mode ${self.startup-nsh} startup.nsh
    guestfish --remote copy-in startup.nsh /

    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/AppleImageCodec.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/FirmwareVolume.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/AppleKeyAggregator.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/AppleUITheme.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/AppleKeyFeeder.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/off/HashServiceFix.efi /ESP/EFI/CLOVER/drivers/UEFI

    guestfish --remote copy-in work/EFI/CLOVER/drivers/UEFI/VBoxHfs.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/UEFI/SMCHelper.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/UEFI/FSInject.efi /ESP/EFI/CLOVER/drivers/UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers/UEFI/AptioInputFix.efi /ESP/EFI/CLOVER/drivers/UEFI

    guestfish --remote copy-in work/EFI/CLOVER/tools /ESP/EFI/CLOVER
    substituteAll ${./config.plist.template} work/config.plist
    guestfish --remote copy-in work/config.plist /ESP/EFI/CLOVER
    guestfish --remote rm /ESP/EFI/CLOVER/drivers/UEFI/AudioDxe.efi
    guestfish --remote umount-all
    guestfish --remote shutdown
    mv clover2.img $out
  '';
  cloverVersion = "5130";
  clover-iso-7z = fetchurl {
    url = "https://github.com/CloverHackyColor/CloverBootloader/releases/download/${self.cloverVersion}/Clover-${self.cloverVersion}-X64.iso.7z";
    sha256 = "0fv0mw03fjqvlhrnv9zixp88dm3ak4sjq84kfs7m6zglq83ar2lx";
  };
  clover-iso = runCommand "clover.iso" { buildInputs = [ p7zip ]; } ''
    7z x ${self.clover-iso-7z}
    mv -v *.iso $out
  '';
  # https://github.com/kholia/OSX-KVM/blob/bda4cc8e698356510c27747b7a929339f450890c/Catalina/startup.nsh
  startup-nsh = runCommand "startup.nsh" {} ''
    echo "fs0:\EFI\CLOVER\CLOVERX64.efi" > $out
  '';
})

