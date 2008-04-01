attrs :

# check jobs-helpers.nix for documentation.
with (import ./jobs-helpers.nix) attrs;

{

  javaFrontSyntaxTrunk = makeEasyJob {
    spec = specs.javaFrontSyntax;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

  javaFrontTrunk = makeEasyJob {
    spec = specs.javaFront;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

  jimpleFrontTrunk = makeEasyJob {
    spec = specs.jimpleFront;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

  strategoLibrariesTrunk = makeEasyJob {
    spec = specs.strategoLibraries;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

  strategoShellTrunk = makeEasyJob {
    spec = specs.strategoShell;
    makeInfoURL = makeInfoURL.usingBaseline;
  };

  # Stratego/XT is a non-standard job, therefore we cannot use makeEasyJob.
  strategoxtTrunk = makeJob {
    args = [
      "../jobs/strategoxt/strategoxt.nix"
      "trunkRelease"
      "/data/webserver/dist/strategoxt2/strategoxt"
      "http://releases.strategoxt.org/strategoxt"
      "/data/webserver/dist/nix-cache"
      "http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache"
    ];

    inputs = {
      strategoxtCheckout = svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/strategoxt/trunk;
      systems = pathInput ./systems.nix;
      atermInfo = infoInput baseline.aterm;
      sdf2BundleInfo = infoInput baseline.sdf;
      strategoxtBaselineTarball = urlInput http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt/strategoxt-0.17M3pre17632/strategoxt-0.17M3pre17632.tar.gz;
      # ftp://ftp.strategoxt.org/pub/stratego/StrategoXT/baseline/latest/strategoxt.tar.gz
    };

    notifyAddresses = ["karltk@strategoxt.org" "martin.bravenboer@gmail.com" "e.visser@tudelft.nl"];
  };

  # The Stratego/XT manual is a non-standard job, therefore we cannot use makeEasyJob.
  strategoxtManualTrunk = makeJob {
    args = [
      "../jobs/strategoxt/custom/manual.nix"
      "trunkRelease"
      "/data/webserver/dist/strategoxt2/strategoxt-manual"
      "http://releases.strategoxt.org/strategoxt-manual"
      "/data/webserver/dist/nix-cache"
      "http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache"
    ];

    inputs = {
      strategoxtManualCheckout = svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/strategoxt-manual/trunk;
      systems = pathInput ./systems.nix;
      atermInfo = infoInput baseline.aterm;
      sdf2BundleInfo = infoInput baseline.sdf;
      strategoxtInfo = infoInput baseline.strategoxt;
    };

    notifyAddresses = ["karltk@strategoxt.org" "martin.bravenboer@gmail.com" "e.visser@tudelft.nl"];
  };

  /**
   * Meta-Environment
   */
  metaBuildEnvTrunk = makeEasyJob {
    spec = specs.metaBuildEnv;
  };

  atermTrunk = makeEasyJob {
    spec = specs.aterm;
  };

  atermBranch64 = makeEasyJob {
    spec = specs.aterm;
    svn = "branch64";
    dirName = "aterm64";
  };

  sdfLibraryTrunk = makeEasyJob {
    spec = specs.sdfLibrary;
  };

  /* toolbuslibTrunk = makeEasyJob {
    spec = specs.toolbuslib;
  }; */

  toolbuslibTrunk64 = makeEasyJob {
    spec = specs.toolbuslib;
    dirName = "toolbuslib-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  cLibraryTrunk64 = makeEasyJob {
    spec = specs.cLibrary;
    dirName = "c-library-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  configSupportTrunk64 = makeEasyJob {
    spec = specs.configSupport;
    dirName = "config-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  errorSupportTrunk64 = makeEasyJob {
    spec = specs.errorSupport;
    dirName = "error-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  tideSupportTrunk64 = makeEasyJob {
    spec = specs.tideSupport;
    dirName = "tide-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  relationStoresTrunk64 = makeEasyJob {
    spec = specs.relationStores;
    dirName = "relation-stores-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  ptSupportTrunk64 = makeEasyJob {
    spec = specs.ptSupport;
    dirName = "pt-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  ptableSupportTrunk64 = makeEasyJob {
    spec = specs.ptableSupport;
    dirName = "ptable-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  sglrTrunk64 = makeEasyJob {
    spec = specs.sglr;
    dirName = "sglr-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  asfSupportTrunk64 = makeEasyJob {
    spec = specs.asfSupport;
    dirName = "asf-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  ascSupportTrunk64 = makeEasyJob {
    spec = specs.ascSupport;
    dirName = "asc-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  sdfSupportTrunk64 = makeEasyJob {
    spec = specs.sdfSupport;
    dirName = "sdf-support-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  pgenTrunk64 = makeEasyJob {
    spec = specs.pgen;
    dirName = "pgen-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };

  sdf2BundleTrunk64 = makeEasyJob {
    spec = specs.sdf2Bundle;
    dirName = "sdf2-bundle-with-aterm64";
    makeInfoURL = makeInfoURL.withATerm64;
  };
}


/*
  javaFrontSyntaxTrunk2 = makeStrategoXTJob {
    dirName = "java-front-syntax2";
    inputs = {
      javaFrontSyntaxCheckout = attrs.svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/java-front/trunk/syntax;
      atermInfo = easy.baseline.aterm;
      sdf2BundleInfo = easy.baseline.sdf;
      strategoxtInfo = easy.baseline.strategoxt;
    };

    notifyAddresses = ["martin.bravenboer@gmail.com"];
    jobAttr = "javaFrontSyntaxUnstable";
  };
*/