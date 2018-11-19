with import <nixpkgs> {};
let
  my-terraform = terraform.withPlugins (p: with p; [ aws ]);
in
mkShell {
  buildInputs = [ my-terraform ];
}
