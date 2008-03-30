{makeJob, pathInput, svnInput, svnInputRev} :

rec {
  urlInput = url: {type = "tgz"; url = url;};
  infoInput = url : urlInput "${url}/release-info.xml";

  makeStrategoXTJob = attrs : makeJob (attrs // {
    args = [
      # directory relative to the supervisor.
      "../jobs/strategoxt2/releases.nix"
      attrs.jobAttr
      "/data/webserver/dist/strategoxt2/${attrs.dirName}"
      "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt2/${attrs.dirName}"
      "/data/webserver/dist/nix-cache"
      "http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache"
    ];

    inputs = {
      systems = pathInput ./systems.nix;
    } // attrs.inputs;
  });

  /**
   * Current Stratego/XT baseline packages.
   */
  baseline = 
    let urls = import ./baseline.nix;
     in { aterm = infoInput urls.aterm;
          sdf = infoInput urls.sdf;
          strategoxt = infoInput urls.strategoxt;
          strategoLibraries = infoInput urls.strategoLibraries;
        };

  /**
   * This job function makes a buildfarm job based on a specification of
   * a package in packages.nix. It automatically adds the svn inputs
   * and the releaae-info.xml files of the requirements.
   */
  makeEasyJob = attrs :
    let refspec = reflect (attrs.spec);
     in makeStrategoXTJob (({
          dirName = refspec.packageName;

          notifyAddresses =
            refspec.notifyAddresses;

          jobAttr =
            refspec.jobAttr attrs.stable;

          } // attrs)
          // {
            inputs = 
              ((refspec.svnInputAttrs attrs.svn) // refspec.requiresInputs)
              //  (if attrs ? inputs then attrs.inputs else {});
          });

  /**
   * Reflection tools for package specifications.
   */
  reflect = somespec : 
    let spec = somespec {};
     in rec {
      /**
       * packageName is optional. We fall back to the fullName
       */
      packageName =
        if spec ? packageName then
          spec.packageName
        else
          spec.fullName;

      /**
       * notifyAddresses are optional. We fall back to the contactEmail.
       */
      notifyAddresses =
        if spec ? notifyAddresses then
          spec.notifyAddresses
        else
          [spec.contactEmail];

      /**
       * if stable, then the job attribute is by convention ${attrPrefix}Stable.
       * if not stable, then ${attrPrefix}Unstable.
       */
      jobAttr = stable :
        if stable then
          spec.attrPrefix + "Stable"
        else
          spec.attrPrefix + "Unstable";

      /**
       * The svn input is by convention ${attrPrefix}Checkout.
       */
      svnInputAttrName =
        spec.attrPrefix + "Checkout";

      /**
       * The package description must have an svn attribute set
       * with attributes for the variant.
       */
      svnInputAttrValue = variant :
        svnInput (builtins.getAttr variant spec.svn);

      svnInputAttrs = variant :
        (builtins.listToAttrs [
          { name = svnInputAttrName;
            value = svnInputAttrValue variant;
          }
        ]);

      /**
       * The info attribute name is by convention ${attrPrefix}Info
       */
      infoInputAttr =
        { name = infoInputAttrName;
          value = infoInputAttrValue;
        };

      infoInputAttrName =
        spec.attrPrefix + "Info";

      infoInputAttrValue =
        if spec.packageName == "aterm" then
          baseline.aterm
        else if spec.packageName == "sdf2-bundle" then
          baseline.sdf
        else if spec.packageName == "strategoxt" then
          baseline.strategoxt
        else
          infoInput "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt/${spec.packageName}-unstable-latest/";

      requiresInputs =
        builtins.listToAttrs (
          map (somespec : (reflect somespec).infoInputAttr) requiresClosure
        );

      /**
       * Take the closure of requirements.
       */
      requiresClosure =
        let closure = somespec :
              somespec.requires ++ (concatLists (map (x : closure (x {})) somespec.requires));
 
            fold = op: nul: list:
              if list == []
                then nul
              else op (builtins.head list) (fold op nul (builtins.tail list));

            concatLists =
              fold (x: y: x ++ y) [];

         in (closure spec) ++ (concatLists (map (x : closure (x {})) spec.svnRequires)) ++ spec.svnRequires;
    };
}