attrs :

let easy = (import ./easy-job.nix) attrs;
    makeEasyJob = easy.makeEasyJob;
    makeStrategoXTJob = easy.makeStrategoXTJob;

    specs =
      (import ../../../../release/jobs/strategoxt2/packages.nix);

 in {

  javaFrontSyntaxTrunk = makeEasyJob {
    spec = specs.javaFrontSyntax;
  };

  javaFrontTrunk = makeEasyJob {
    spec = specs.javaFront;
  };

  jimpleFrontTrunk = makeEasyJob {
    spec = specs.jimpleFront;
  };

  strategoLibrariesTrunk = makeEasyJob {
    spec = specs.strategoLibraries;
  };

  strategoShellTrunk = makeEasyJob {
    spec = specs.strategoShell;
  };

  metaBuildEnvTrunk = makeEasyJob {
    spec = specs.metaBuildEnv;
  };

  atermBranch64 = makeEasyJob {
    spec = specs.aterm;
    svn = "branch64";
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