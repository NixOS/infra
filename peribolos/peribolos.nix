{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "peribolos";
  version = "0.0.7";

  src = fetchFromGitHub {
    owner = "uwu-tools";
    repo = "peribolos";
    rev = "refs/tags/v${version}";
    hash = "sha256-6R7jf+jcsmQ9CKBIxgYQGunfft8+zd4p2xspSxE+9WY=";
  };

  vendorHash = "sha256-1vO9emMq6D8C/NqC4AbKG3Omt17hn+V6pBlNT8oizYg=";

  subPackages = [ "." ];

  meta = with lib; {
    description = "Peribolos allows the org settings, teams and memberships to be declared in a yaml file. GitHub is then updated to match the declared configuration.";
    homepage = "https://github.com/uwu-tools/peribolos";
    changelog = "https://github.com/uwu-tools/peribolos/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ zimbatm ];
    mainProgram = "peribolos";
  };
}

