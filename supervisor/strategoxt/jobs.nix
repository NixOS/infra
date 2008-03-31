attrs :

let # The easy buildfarm configuration is a system based on a
    # declarative package description, and dependencies that are
    # downloaded directly from release pages produced by the
    # buildfarm.
    easy = (import ./easy-job.nix) attrs;

    # Reflect is a set of functions for reflecting over package
    # specifications.
    reflect = easy.reflect;

    # infoInput turns a URL of a release into a buildfarm input,
    # attaching release-info.xml to the URL.
    infoInput = easy.infoInput;

    # Main function to make jobs.
    makeEasyJob = easy.makeEasyJob;

    # A more generic job. Requires more configuration though! You need
    # to specify yourself: dirName, notifyAddresses, jobAttr in
    # releases.nix, and inputs.
    makeStrategoXTJob = easy.makeStrategoXTJob;

    # The file packages.nix describes packages, their dependencies,
    # specific platform requirements, etc.
    specs =
      (import ../../../../release/jobs/strategoxt2/packages.nix);

    # Current Stratego/XT baseline packages.
    baseline = 
      import ./baseline.nix;

    # The makeEasyJob function accepts an argument
    # 'makeInfoURL'. makeInfoURL is a function that given a package
    # specification returns a URL to a release-info.xml file. This
    # file provides the buildfarm with information about available
    # source tarballs and RPMs for this package.

    # The default makeInfoURL always uses the latest -unstable release
    # of a package. You only need to specify your own makeInfoURL if
    # you want a different behaviour. Some useful makeInfoURL variants
    # are defined here.
    makeInfoURL = {

      # A common example of makeInfoURL is 'usingBaseline'. This
      # makeInfoURL variant uses baseline releases for aterm,
      # sdf2-bundle, and strategoxt. The URLs of the baseline are
      # specified in 'baseline.nix'.
      usingBaseline = spec :
        let packageName = reflect.packageName spec;
         in if packageName == "aterm" then
              infoInput baseline.aterm
            else if packageName == "sdf2-bundle" then
              infoInput baseline.sdf
            else if packageName == "strategoxt" then
              infoInput baseline.strategoxt
            else if packageName == "stratego-libraries" then
              infoInput baseline.strategoLibraries
            else
              infoInput "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt2/${packageName}/${packageName}-unstable/";

      # Stratego/XT uses a branch of the ATerm library. For the
      # Meta-Environment packages to built against this branch, and
      # against other releases that have been built using this branch,
      # we use this makeInfoURL function, which attaches
      # '-with-aterm64' to package names.

      # This function is not required for Stratego/XT packages, since
      # these are all built using with this branch of the ATerm
      # library.
      withATerm64 = spec :
        let packageName = reflect.packageName spec;
         in if packageName == "aterm" then
              infoInput "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt2/aterm64/${packageName}-unstable/"
            else if reflect.isRequired spec specs.aterm then
              infoInput "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt2/${packageName}-with-aterm64/${packageName}-unstable/"
            else
              infoInput "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt2/${packageName}/${packageName}-unstable/";
    };

 in {

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