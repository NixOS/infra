attrs :

let easy = (import ./easy-job.nix) attrs;
    makeEasyJob = easy.makeEasyJob;

    specs =
      (import ../jobs/strategoxt2/packages.nix);

 in {
  javaFrontSyntaxTrunk = makeEasyJob {
    spec = specs.javaFrontSyntax;
    stable = false;
    svn = "trunk";
  };
}

/*

{
  javaFrontSyntaxTrunk = job {
    dirName = "java-front-syntax";
    inputs = {
      javaFrontSyntax = svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/java-front/trunk/syntax;
      atermInfo = baseline.aterm;
      sdf2BundleInfo = baseline.sdf;
      strategoxtInfo = baseline.strategoxt;
    };

    notifyAddresses = [bravenboer];
    jobAttr = "javaFrontSyntaxUnstable";
  };
}
  */
