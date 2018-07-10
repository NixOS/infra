with import <nixpkgs> {};
mkShell {
  buildInputs = [ terraform-full ];
}
