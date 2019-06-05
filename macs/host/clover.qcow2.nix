{ lib
, runCommand
, fetchurl
, libguestfs
, libguestfs-appliance
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
    guestfish --remote copy-in work/EFI/BOOT /ESP/EFI
    guestfish --remote copy-in work/EFI/CLOVER/CLOVERX64.efi /ESP/EFI/CLOVER
    guestfish --remote copy-in work/EFI/CLOVER/drivers64UEFI /ESP/EFI/CLOVER
    guestfish --remote copy-in work/EFI/CLOVER/drivers-Off/drivers64UEFI/PartitionDxe-64.efi /ESP/EFI/CLOVER/drivers64UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers-Off/drivers64UEFI/ApfsDriverLoader-64.efi /ESP/EFI/CLOVER/drivers64UEFI
    guestfish --remote copy-in work/EFI/CLOVER/drivers-Off/drivers64UEFI/OsxAptioFix3Drv-64.efi /ESP/EFI/CLOVER/drivers64UEFI
    guestfish --remote copy-in work/EFI/CLOVER/tools /ESP/EFI/CLOVER
    substituteAll ${./../dist/config.plist.template} work/config.plist
    guestfish --remote copy-in work/config.plist /ESP/EFI/CLOVER
    guestfish --remote rm /ESP/EFI/CLOVER/drivers64UEFI/AudioDxe-64.efi
    guestfish --remote umount-all
    guestfish --remote shutdown
    mv clover2.img $out
  '';
  cloverVersion = "4934";
  clover-iso-lzma = fetchurl {
    url = "mirror://sourceforge/cloverefiboot/CloverISO-${self.cloverVersion}.tar.lzma";
    sha256 = "0ivwaapgir2yvsyp7gi9ddj6r97j99n99cz0xwqhcrijimp06hcl";
  };
  clover-iso = runCommand "clover.iso" {} ''
    tar -xvf ${self.clover-iso-lzma}
    mv -v *.iso $out
  '';
})
