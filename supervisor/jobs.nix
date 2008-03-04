let

  /* Helper functions. */
  
  pathInput = path: {type = "path"; path = toString path;};
  svnInput = url: {type = "svn"; url = url;};
  svnInputRev = url: rev: {type = "svn"; url = url; rev = rev;};

  makeJob = attrs: attrs // {
    jobScript = defaultJobScript;
    inputs = {
      job = pathInput /etc/nixos/release;
      #job = svnInput jobBaseline;
      nixpkgs = svnInputRev nixpkgsBaseline 10894;
    } // attrs.inputs;
  };


  /* Common variables for (almost) all jobs. */

  jobBaseline = https://svn.cs.uu.nl:12443/repos/trace/release/trunk;

  nixpkgsBaseline = https://svn.cs.uu.nl:12443/repos/trace/nixpkgs/trunk;

  defaultJobScript = "generic-dist/build+upload.sh";

  cacheDir = http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache;


  /* Common variables for UT project jobs. */

  utFmtDistDir = http://buildfarm.st.ewi.tudelft.nl/releases/ut-fmt;

  utFmtPassword = "/home/buildfarm/secrets/ut-fmt-upload-passwd";


in

{

  /* TorX */

  torxHead = makeJob {
    inputs = {
      torxHead = pathInput /tmp/torx-buildfarm.tgz;
    };
    notifyAddresses = ["e.dolstra@tudelft.nl"];
    secrets = utFmtPassword;
    args = ["./jobs/ut-fmt/torx.nix" "torxHeadRelease" utFmtDistDir cacheDir];
    #noRelease = true;
    disabled = true;
  };

  /* Groove */

  grooveHead = makeJob {
    inputs = {
    };
    notifyAddresses = ["e.dolstra@tudelft.nl"];
    secrets = utFmtPassword;
    args = ["./jobs/ut-fmt/groove.nix" "grooveHeadRelease" utFmtDistDir cacheDir];
    #noRelease = true;
  };

}
