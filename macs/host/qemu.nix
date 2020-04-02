
{ config, lib, pkgs, ... }:
let
  inherit (config.macosGuest.guest) threads cores sockets memoryInMegs
    ovmfCodeFile ovmfVarsFile cloverImage zvolName snapshotName
    guestConfigDir persistentConfigDir;
  inherit (lib) mkIf;

  zvolDevice = "/dev/zvol/${zvolName}";
  snapshot = "${zvolName}@${snapshotName}";
in {
  config = mkIf config.macosGuest.enable {
    systemd.services.create-macos-secrets = {
      path = with pkgs; [ openssh ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        if [ ! -f ${persistentConfigDir}/etc/ssh/ssh_host_ed25519_key ]; then
          mkdir -p ${persistentConfigDir}/etc/ssh
          ssh-keygen -A -f ${persistentConfigDir}
        fi
      '';
    };

    systemd.services."run-macos-vm" = rec {
      requires = [ "create-macos-secrets.service" "dhcpd4.service" "kresd@1.service" "network-online.target" ];
      after = requires;
      wantedBy = [ "multi-user.target" ];
      wants = [ "netcatsyslog.service" "healthcheck-macos-vm.timer" ];
      before = [ "healthcheck-macos-vm.timer" ];
      path = with pkgs; [ zfs qemu cdrkit rsync findutils ];

      serviceConfig.PrivateTmp = true;

      preStart = ''
        zfs rollback ${snapshot}

        # Create a cloud-init style cdrom
        rm -rf /tmp/cdr
        cp -r ${persistentConfigDir} /tmp/cdr
        rsync -r ${guestConfigDir}/ /tmp/cdr
        cd /tmp/cdr
        find .
        genisoimage -v -J -r -V CONFIG -o /tmp/config.iso .
      '';
      postStop = "zfs rollback ${snapshot}";
      script = ''
        qemu-system-x86_64 \
            -enable-kvm \
            -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+aes,+xsave,+avx,+xsaveopt,avx2,+smep \
            -machine pc-q35-2.9 \
            -smp cpus=${toString (cores * threads * sockets)},cores=${toString cores},threads=${toString threads},sockets=${toString sockets} \
            -m ${toString memoryInMegs} \
            -usb -device usb-kbd -device usb-tablet \
            -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
            -drive if=pflash,format=raw,readonly,file=${ovmfCodeFile} \
            -drive if=pflash,format=raw,snapshot=on,file=${ovmfVarsFile} \
            -smbios type=2 \
            -device ich9-intel-hda -device hda-duplex \
            -device ide-drive,bus=ide.2,drive=Clover \
            -drive id=Clover,if=none,snapshot=on,format=qcow2,file='${cloverImage}' \
            -device ide-drive,bus=ide.1,drive=MacHDD \
            -drive id=MacHDD,cache=unsafe,if=none,file=${zvolDevice},format=raw \
            -device ide-drive,bus=ide.0,drive=config \
            -drive id=config,if=none,snapshot=on,media=cdrom,file=/tmp/config.iso \
            -netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000-82545em,netdev=net0,id=net0,mac=${config.macosGuest.guest.MACAddress} \
            -vnc 127.0.0.1:0 \
            -no-reboot
      '';
    };

    systemd.timers.healthcheck-macos-vm = {
      enable = true;
      description = "Verify the macOS VM is listening";
      partOf = [ "run-macos-vm.service"];

      timerConfig = {
        OnActiveSec = 900;
        OnCalendar = "hourly";
        Unit = "healthcheck-macos-vm.service";
        Persistent = "yes";
      };
    };

    systemd.services.healthcheck-macos-vm = {
      enable = true;

      script = ''
        if ${pkgs.curl}/bin/curl ${config.macosGuest.network.interiorNetworkPrefix}.2:9100 > /dev/null; then
          echo "Appears to be up!"
        else
          echo "Appears to be down, restarting run-macos-vm"
          systemctl restart run-macos-vm.service
        fi
      '';
    };
  };
}
