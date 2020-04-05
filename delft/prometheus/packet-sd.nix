{ buildGo112Module, fetchFromGitHub, lib }:
buildGo112Module rec {
  pname = "prometheus-packet-sd";
  version = "v0.0.3";

  src = fetchFromGitHub {
    owner = "packethost";
    repo = "prometheus-packet-sd";
    rev = "v0.0.3";
    sha256 = "sha256-2k8AsmyhQNNZCzpVt6JdgvI8IFb5pRi4ic6Yn2NqHMM=";
  };

  modSha256 = "sha256-I2QSxtNH5KcY7YBDI5XgoIa3bzGBIhDrxweqc34L0Ug=";

  subPackages = [ "." ];

  meta = with lib; {
    description = "Prometheus service discovery for Packet.";
    homepage = https://github.com/packethost/prometheus-packet-sd;
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
