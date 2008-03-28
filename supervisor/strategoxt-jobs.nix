{makeJob, pathInput, svnInput, svnInputRev} :

let
  urlInput = url: {type = "tgz"; url = url;};
  infoInput = url : urlInput "${url}/release-info.xml";

  job = attrs : makeJob (attrs // {
    dirname ="strategoxt";

    args = [
      "../jobs/strategoxt2/releases.nix" /* brrr */
      attrs.jobAttr
      "/data/webserver/dist/strategoxt-tmp/${attrs.dirName}"
      "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt-tmp/${attrs.dirName}"
      "/data/webserver/dist/nix-cache"
      "http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache"
    ];

    inputs = {
      systems = pathInput ./systems.nix;
    } // attrs.inputs;
  });

  bravenboer = "martin.bravenboer@gmail.com";
  kalleberg = "karltk@strategoxt.org";
  visser = "e.visser.@tudelft.nl";

  baseline = 
    let urls = import ./baseline.nix;
     in { aterm = infoInput urls.aterm;
          sdf = infoInput urls.sdf;
          strategoxt = infoInput urls.strategoxt;
          strategoLibraries = infoInput urls.strategoLibraries;
        };

in

{
  javaFrontSyntaxTrunk = job {
    dirName = "java-front-syntax"; /* @todo should be automated */
    inputs = {
      javaFrontSyntax = svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/java-front/trunk/syntax;
      /* @todo it should be easy to automate this now (based on info in packages.nix) */      
      atermInfo = baseline.aterm;
      sdf2BundleInfo = baseline.sdf;
      strategoxtInfo = baseline.strategoxt;
    };

    notifyAddresses = [bravenboer];
    jobAttr = "javaFrontSyntaxUnstable";
  };
}
