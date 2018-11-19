with import <nixpkgs> {};
let
  my-terraform = terraform.withPlugins (p: with p; [
    aws
    fastly
  ]);
in
mkShell {
  buildInputs = [ my-terraform ];
}
