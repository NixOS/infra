{ buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  pname = "prometheus-packet-sd";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "packethost";
    repo = "prometheus-packet-sd";
    rev = "v${version}";
    sha256 = "0y2c73irk1xy3raha9yx1j5ja5h2phalnwjcbsgpr6jnfs0v6shh";
  };

  modSha256 = "1cgyfc77fdrmv7f2cy0qpwgmn9wpmaa66806brflkpkq1nc9dr5b";

  subPackages = [ "." ];

  meta = with lib; {
    description = "Prometheus service discovery for Packet.";
    homepage = https://github.com/packethost/prometheus-packet-sd;
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}