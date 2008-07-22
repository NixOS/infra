let

  /* Helper functions. */
  
  pathInput = path: {type = "path"; path = toString path;};
  svnInput = url: {type = "svn"; url = url;};
  svnInputRev = url: rev: {type = "svn"; url = url; rev = rev;};

  makeJob = attrs: attrs // {
    jobScript = defaultJobScript;
    inputs = {
      job = pathInput ../../../release;
      #job = svnInput jobBaseline;
      nixpkgs = svnInputRev nixpkgsBaseline 12133;
    } // attrs.inputs;
  };


  /* Common variables for (almost) all jobs. */

  jobBaseline = https://svn.nixos.org/repos/nix/release/branches/new;

  nixpkgsBaseline = https://svn.nixos.org/repos/nix/nixpkgs/trunk;

  defaultJobScript = "generic-dist/build+release.sh";

  defaultURL = http://buildfarm.st.ewi.tudelft.nl/releases;

  cacheDir = "/data/webserver/dist/nix-cache";
  cacheURL = http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache;


  /* Common variables for Nix-related jobs. */

  makeNixJob = attrs: makeJob ({
    notifyAddresses = ["e.dolstra@tudelft.nl"];
    args = [
      attrs.jobExpr
      attrs.jobAttr
      "/data/webserver/dist/nix/${attrs.dirName}"
      "http://nixos.org/releases/${attrs.dirName}"
      cacheDir
      http://nixos.org/releases/nix-cache
    ];
  } // attrs);
    

  /* Common variables for UU ST jobs. */

  makeUUSTJob = attrs: makeJob ({
    notifyAddresses = ["ariem@cs.uu.nl"];
    args = [
      attrs.jobExpr
      attrs.jobAttr
      "/data/webserver/dist/uust/${attrs.dirName}"
      "${defaultURL}/uust/${attrs.dirName}"
      cacheDir
      cacheURL
    ];
  } // attrs);

  
  /* Common variables for UT project jobs. */

  utFmtDistDir = "/data/webserver/dist/ut-fmt";
  utFmtDistURL = http://buildfarm.st.ewi.tudelft.nl/releases/ut-fmt;

  strategoxtJobs =
    (import ./strategoxt/jobs.nix) {
      inherit makeJob pathInput svnInput svnInputRev;
    };

  spoofaxJobs = 
    (import ./spoofax/jobs.nix) {
      inherit makeJob pathInput svnInput svnInputRev;
    };

in
  strategoxtJobs //
  spoofaxJobs    // {
  

  /* Nix */

  nixTrunk = makeNixJob {
    dirName = "nix";
    inputs = {
      nixCheckout = svnInput https://svn.nixos.org/repos/nix/nix/trunk;
    };
    jobExpr = "../jobs/nix/nix.nix";
    jobAttr = "nixRelease";
  };
  
  nixNoBDBBranch = makeNixJob {
    dirName = "nix-no-bdb";
    inputs = {
      nixCheckout = svnInput https://svn.nixos.org/repos/nix/nix/branches/no-bdb;
    };
    jobExpr = "../jobs/nix/nix.nix";
    jobAttr = "nixRelease";
  };
  

  /* Nixpkgs */

  nixpkgsTrunk = makeNixJob {
    dirName = "nixpkgs";
    inputs = {
      nixpkgsCheckout = svnInput https://svn.nixos.org/repos/nix/nixpkgs/trunk;
    };
    jobExpr = "../jobs/nix/nixpkgs.nix";
    jobAttr = "nixpkgsRelease";
  };

  nixpkgsStdenvBranch = makeNixJob {
    dirName = "nixpkgs-stdenv-branch";
    inputs = {
      nixpkgsCheckout = svnInput https://svn.nixos.org/repos/nix/nixpkgs/branches/stdenv-updates;
    };
    jobExpr = "../jobs/nix/nixpkgs.nix";
    jobAttr = "nixpkgsRelease";
  };


  /* NixOS */
  
  nixosTrunk = makeNixJob {
    dirName = "nixos";
    inputs = {
      nixosCheckout = svnInput https://svn.nixos.org/repos/nix/nixos/trunk;
      nixpkgsCheckout = svnInput https://svn.nixos.org/repos/nix/nixpkgs/trunk;
    };
    jobExpr = "../jobs/nix/nixos.nix";
    jobAttr = "nixosRelease";
    disabled = true;
  };
  
  
  /* PatchELF */

  patchelfTrunk = makeNixJob {
    dirName = "patchelf";
    inputs = {
      patchelfCheckout = svnInput https://svn.nixos.org/repos/nix/patchelf/trunk;
    };
    jobExpr = "../jobs/nix/patchelf.nix";
    jobAttr = "patchelfRelease";
  };


  /* UU ST group jobs */

  uulibTrunk = makeUUSTJob {
    dirName = "uulib";
    inputs = {
      uulibCheckout = svnInput https://svn.cs.uu.nl:12443/repos/uust-repo/uulib/trunk/;
    };
    jobExpr = "../jobs/hut/uulib.nix";
    jobAttr = "uulibRelease";
  };

  uuagcTrunk = makeUUSTJob {
    dirName = "uuagc";
    inputs = {
      uuagcCheckout = svnInput https://svn.cs.uu.nl:12443/repos/uust-repo/uuagc/trunk/;
    };
    jobExpr = "../jobs/hut/uuagc.nix";
    jobAttr = "uuagcRelease";
  };
  
  ehTrunk = makeUUSTJob {
    dirName = "eh";
    inputs = {
      ehCheckout = svnInput https://svn.cs.uu.nl:12443/repos/EHC/trunk/EHC/;
    };
    jobExpr = "../jobs/hut/eh.nix";
    jobAttr = "ehRelease";
  };

  heliumTrunk = makeUUSTJob {
    dirName = "helium";
    inputs = {
      systemCheckout = svnInput https://svn.cs.uu.nl:12443/repos/heliumsystem;
      heliumCheckout = svnInput https://svn.cs.uu.nl:12443/repos/helium/trunk;
      topCheckout = svnInput https://svn.cs.uu.nl:12443/repos/Top/trunk;
      lvmCheckout = svnInput https://svn.cs.uu.nl:12443/repos/lvm/trunk;
      hintCheckout = svnInput https://svn.cs.uu.nl:12443/repos/hint/trunk;
    };
    jobExpr = "../jobs/hut/helium.nix";
    jobAttr = "heliumRelease";
  }; 
  

  /* TorX */

  /*
  torxHead = makeJob {
    inputs = {
      torxHead = pathInput /tmp/torx-buildfarm.tgz;
    };
    notifyAddresses = ["e.dolstra@tudelft.nl"];
    args = ["./jobs/ut-fmt/torx.nix" "torxHeadRelease" utFmtDistDir cacheDir];
    #noRelease = true;
    disabled = true;
  };
  */

  
  /* Groove */

  /*
  grooveHead = makeJob {
    inputs = {
    };
    notifyAddresses = ["e.dolstra@tudelft.nl"];
    args = ["./jobs/ut-fmt/groove.nix" "grooveHeadRelease" utFmtDistDir cacheDir];
    #noRelease = true;
  };
  */

}
