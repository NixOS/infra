{makeJob, pathInput, svnInput, svnInputRev} :

let
  urlInput = url: {type = "tgz"; url = url;};

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
      systems = svnInput https://svn.cs.uu.nl:12443/repos/trace/configurations/trunk/tud/supervisor/systems.nix;
    } // attrs.inputs;
  });

  bravenboer = "martin.bravenboer@gmail.com";
  kalleberg = "karltk@strategoxt.org";
  visser = "e.visser.@tudelft.nl";

  info = {
    baseline = {
      aterm = urlInput http://buildfarm.st.ewi.tudelft.nl/releases/meta-environment/aterm-2.5pre21238-l2q7rg38/release-info.xml;
      sdf = urlInput http://buildfarm.st.ewi.tudelft.nl/releases/meta-environment/sdf2-bundle-2.4pre212034-2nspl1xc/release-info.xml;
      strategoxt = urlInput http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt/strategoxt-0.17M3pre17483/release-info.xml;
      strategoLibraries = urlInput http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt/stratego-libraries-0.17pre17483-zvwcks5g/release-info.xml;
    };
  };

in

{
  javaFrontSyntaxTrunk = job {
    dirName = "java-front-syntax"; /* @todo should be automated */
    inputs = {
      javaFrontSyntax = svnInput https://svn.cs.uu.nl:12443/repos/StrategoXT/java-front/trunk/syntax;
      /* @todo it should be easy to automate this now (based on info in packages.nix) */      
      atermInfo = info.baseline.aterm;
      sdf2BundleInfo = info.baseline.sdf;
      strategoxtInfo = info.baseline.strategoxt;
    };

    notifyAddresses = [bravenboer];
    jobAttr = "javaFrontSyntaxUnstable";
  };
}
