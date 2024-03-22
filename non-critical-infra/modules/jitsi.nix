{ pkgs, ... }:
{
  services.jitsi-meet = {
    enable = true;
    hostName = "jitsi.nixos.org";
    config = {
      enableWelcomePage = true;
      requireDisplayName = true;
      analytics.disabled = true;
      startAudioOnly = true;
      channelLastN = 4;
      lobby = {
        autoKnock = true;
        enableChat = false;
      };
      stunServers = [
        { urls = "turn:turn.matrix.org:3478?transport=udp"; }
        { urls = "turn:turn.matrix.org:3478?transport=tcp"; }
      ];
      constraints.video.height = {
        ideal = 720;
        max = 1080;
        min = 240;
      };
      remoteVideoMenu.disabled = false;
      breakoutRooms.hideAddRoomButton = false;
      maxFullResolutionParticipants = 1;
    };
    updateMucs = {
      "conference.jitsi.nixos.org".extraModules = [
        "muc_mam"
        "vcard_muc"
        "lobby_autostart"
        "secure_domain_lobby_bypass"
      ];
    };

    interfaceConfig = {
      SHOW_JITSI_WATERMARK = false;
      SHOW_WATERMARK_FOR_GUESTS = false;
      GENERATE_ROOMNAMES_ON_WELCOME_PAGE = false;
      DISABLE_PRESENCE_STATUS = true;
    };
    secureDomain.enable = true;
  };

  services.prosody.extraPluginPaths = [
    "${pkgs.jitsi-prosody-plugins}/lobby_autostart"
    "${pkgs.jitsi-prosody-plugins}/secure_domain_lobby_bypass"
  ];

  services.prosody.extraModules = [ "muc_lobby_rooms" "persistent_lobby" "lobby_autostart" ];
  services.prosody.virtualHosts."jitsi.nixos.org".extraConfig = ''
    modules_enabled = {
      "muc_lobby_rooms";
      "persistent_lobby";
    }
  '';
}
