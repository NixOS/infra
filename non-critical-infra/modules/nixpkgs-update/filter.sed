# replace versioned with the most-compatible (26) not the latest (27)
s|beam\w*2[0-9]*Packages|beam26Packages|g

# 1. replace versioned generic kernels with unversioned
s|linuxKernel.packages.linux_[0-9_]*\.|linuxPackages.|g
# 2. drop other kernels (hardened, xanmod, zen, etc)
/linuxKernel.packages.linux_\w*/d

# replace versioned/jit with the version used by neovim
s|lua\w*Packages|lua51Packages|g

# replace versioned with unversioned
s|llvmPackages_\w*|llvmPackages|g

# replace latest
s|ocamlPackages_latest|ocamlPackages|g

# replace versioned with unversioned
s|php\w*Extensions|phpExtensions|g
s|php\w*Packages|phpPackages|g

# replace versioned/jit with unversioned
s|postgresql\w*Packages|postgresqlPackages|g

# replace versioned with unversioned
s|python3\w*Packages|python3Packages|g

# drop > 4000 packages that can't be updated
/^rPackages.\w*/d

# lix/nix specific overrides of other packages
/lixPackageSets.\w*/d
/nixDependencies.\w*/d

# drop > 100s of other packages that can't be updated
/haskellPackages.\w*/d
/home-assistant-component-tests.\w*/d
/indi-3rdparty.\w*/d
/perl\w*Packages.\w*/d
/python3Packages.mypy-boto3-\w*/{/mypy-boto3-builder/!d}
/python3Packages.types-aiobotocore-\w*/d
/typstPackages.\w*/d
/vimPlugins.nvim-treesitter-legacy-parsers\w*/d
/vimPlugins.nvim-treesitter-parsers\w*/d
