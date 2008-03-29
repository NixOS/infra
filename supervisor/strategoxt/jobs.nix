attrs :

let easy = (import ./easy-job.nix) attrs;
    makeEasyJob = easy.makeEasyJob;
    makeStrategoXTJob = easy.makeStrategoXTJob;

#    specs =
#      (import ../../../../release/jobs/strategoxt2/packages.nix);

 in {
  /*
  javaFrontSyntaxTrunk = makeEasyJob {
    spec = specs.javaFrontSyntax;
    stable = false;
    svn = "trunk";
  }; */

  javaFrontSyntaxTrunk2 = makeStrategoXTJob {
    dirName = "java-front-syntax2";
    inputs = {
      javaFrontSyntax = attrs.svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/java-front/trunk/syntax;
      atermInfo = easy.baseline.aterm;
      sdf2BundleInfo = easy.baseline.sdf;
      strategoxtInfo = easy.baseline.strategoxt;
    };

    notifyAddresses = ["martin.bravenboer@gmail.com"];
    jobAttr = "javaFrontSyntaxUnstable";
  };
}

/*

{
  javaFrontSyntaxTrunk = job {
    dirName = "java-front-syntax";
    inputs = {
      javaFrontSyntax = attrs.svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/java-front/trunk/syntax;
      atermInfo = baseline.aterm;
      sdf2BundleInfo = baseline.sdf;
      strategoxtInfo = baseline.strategoxt;
    };

    notifyAddresses = [bravenboer];
    jobAttr = "javaFrontSyntaxUnstable";
  };
}
  */
