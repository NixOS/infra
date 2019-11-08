{ buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  pname = "prometheus-packet-sd";
  version = "2019-09-28";

  src = fetchFromGitHub {
    owner = "packethost";
    repo = "prometheus-packet-sd";
    rev = "2944af336b2fda49d5840d6cc28877afad0fd031";
    sha256 = "01464m88pcv0zfd6hm4m02phf5b9gj2k04qdd71iir4zvvjgyd6g";
  };

  modSha256 = "sha256-vP1O2YFMCu2P7YnV67yrMSyvWxLwun4cm/Hm5y6W1FY=";

  subPackages = [ "." ];

  meta = with lib; {
    description = "Prometheus service discovery for Packet.";
    homepage = https://github.com/packethost/prometheus-packet-sd;
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}