attrs :

# check jobs-helpers.nix for documentation.
with (import ./jobs-helpers.nix) attrs;

{

  spoofaxATermTrunk = makeEasyJob {
    spec = specs.spoofaxATerm;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

  spoofaxJsglrTrunk = makeEasyJob {
    spec = specs.spoofaxJsglr;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

}

