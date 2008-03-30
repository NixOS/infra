attrs :

let easy = (import ./easy-job.nix) attrs;
    makeEasyJob = easy.makeEasyJob;
    makeStrategoXTJob = easy.makeStrategoXTJob;

    specs =
      (import ../../../../release/jobs/strategoxt2/packages.nix);

 in {

  javaFrontSyntaxTrunk = makeEasyJob {
    spec = specs.javaFrontSyntax;
    useBaseline = true;
  };

  javaFrontTrunk = makeEasyJob {
    spec = specs.javaFront;
    useBaseline = true;
  };

  jimpleFrontTrunk = makeEasyJob {
    spec = specs.jimpleFront;
    useBaseline = true;
  };

  strategoLibrariesTrunk = makeEasyJob {
    spec = specs.strategoLibraries;
    useBaseline = true;
  };

  strategoShellTrunk = makeEasyJob {
    spec = specs.strategoShell;
    useBaseline = true;
  };

  metaBuildEnvTrunk = makeEasyJob {
    spec = specs.metaBuildEnv;
  };

  atermBranch64 = makeEasyJob {
    spec = specs.aterm;
    svn = "branch64";
    dirname = "aterm64";
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