{ config
, pkgs
, ...
}:

let
  packet-sd = pkgs.callPackage ./packages/packet-sd.nix { };
in

{
  age.secrets.packet-sd-env = {
    file = ../../../secrets/packet-sd-env.age;
    owner = "packet-sd";
  };

  users.users.packet-sd = {
    description = "Prometheus Packet Service Discovery";
    isSystemUser = true;
    group = "packet-sd";
  };
  users.groups.packet-sd = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/packet-sd 0755 packet-sd - -"
    "f /var/lib/packet-sd/packet-sd.json 0644 packet-sd - -"
  ];

  systemd.services.prometheus-packet-sd = {
    wantedBy = [
      "multi-user.target"
      "prometheus.service"
    ];
    after = [
      "network.target"
    ];

    serviceConfig = {
      User = "packet-sd";
      Group = "keys";
      ExecStart = "${packet-sd}/bin/prometheus-packet-sd --output.file=/var/lib/packet-sd/packet-sd.json";
      EnvironmentFile = config.age.secrets.packet-sd-env.path;
      Restart = "always";
      RestartSec = "60s";
    };
  };

  services.prometheus = {
    scrapeConfigs = [ {
      job_name = "prometheus-packet-sd";
      metrics_path = "/metrics";
      static_configs = [ {
        targets = [
          "127.0.0.1:9465"
        ];
      } ];
    } {
      job_name = "packet_nodes";
      file_sd_configs = [ {
        files = [ "/var/lib/packet-sd/packet-sd.json" ];
        refresh_interval = "30s";
      } ];
      relabel_configs = [ {
        source_labels = [ "__meta_packet_public_ipv4" ];
        target_label = "__address__";
        replacement = "\${1}:9100";
        action = "replace";
      } {
        source_labels = [ "__meta_packet_facility" ];
        target_label = "facility";
      } {
        source_labels = [ "__meta_packet_facility" ];
        target_label = "packet_facility";
      } {
        source_labels = [ "__meta_packet_plan" ];
        target_label = "plan";
      } {
        source_labels = [ "__meta_packet_plan" ];
        target_label = "packet_plan";
      } {
        # todo: change from _id to _uuid
        source_labels = [ "__meta_packet_switch_id" ];
        target_label = "packet_switch_id";
      } {
        source_labels = [ "__meta_packet_device_id" ];
        target_label = "packet_device_id";
      } {
        source_labels = [ "__meta_packet_state" ];
        target_label = "packet_device_state";
      } {
        source_labels = [ "__meta_packet_short_id" ];
        target_label = "instance";
        replacement = "\${1}.packethost.net";
        action = "replace";
      } {
        source_labels = [ "__meta_packet_tags" ];
        target_label = "role";
        regex = ".*hydra.*";
        replacement = "builder";
        action = "replace";
      } {
        source_labels = [ "__meta_packet_tags" ];
        regex = ".*prometheus-scraping-disabled.*";
        action = "drop";
      } ];
    } ];
  };
}
