{ buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  pname = "prometheus-packet-sd";
  version = "v0.0.3";

  src = fetchFromGitHub {
    owner = "packethost";
    repo = "prometheus-packet-sd";
    rev = "v0.0.3";
    sha256 = "sha256-2k8AsmyhQNNZCzpVt6JdgvI8IFb5pRi4ic6Yn2NqHMM=";
  };

  vendorSha256 = null;

  subPackages = [ "." ];

  meta = with lib; {
    description = "Prometheus service discovery for Packet.";
    homepage = "https://github.com/packethost/prometheus-packet-sd";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
