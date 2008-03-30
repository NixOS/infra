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
   * This job function makes a buildfarm job based on a specification of
   * a package in packages.nix. It automatically adds the svn inputs
   * and the releaae-info.xml files of the requirements.
   */
  makeEasyJob = attrs :
    let makeInfoURL =
          if attrs ? makeInfoURL then attrs.makeInfoURL else defaultMakeInfoURL;
        spec =
          attrs.spec;
        stable =
          if attrs ? stable then attrs.stable else false;
        svn =
          if attrs ? svn then attrs.svn else "trunk";
        customInputs =
          if attrs ? inputs then attrs.inputs else {};
     in makeStrategoXTJob (removeAttrs (({
          dirName =
            reflect.packageName spec;
          notifyAddresses =
            reflect.notifyAddresses spec;
          jobAttr =
            reflect.jobAttr spec stable;
          }
          // attrs)
          // {
            inputs = 
              ((reflect.svnInputs spec svn)
              // (reflect.requiresInputs spec makeInfoURL))
              // customInputs;
          }) ["makeInfoURL"]);

  defaultMakeInfoURL = spec :
     let packageName = reflect.packageName spec;
      in infoInput "http://buildfarm.st.ewi.tudelft.nl/releases/strategoxt2/${packageName}/${packageName}-unstable/";

  /**
   * Some packages reflect of pkgs to determine dependencies
   * and options. We need to accommodate that a bit ...
   */
  fakePkgs =
    {
      stdenv = {
        system = "generic";
      };
    };

  /**
   * Reflection tools for package specifications.
   */
  reflect = rec {
    /**
     * packageName is optional. We fall back to the fullName
     */
    packageName = spec :
      if (spec fakePkgs) ? packageName then
        (spec fakePkgs).packageName
      else
        (spec fakePkgs).fullName;

    /**
     * notifyAddresses are optional. We fall back to the contactEmail.
     */
    notifyAddresses = spec :
      if (spec fakePkgs) ? notifyAddresses then
        (spec fakePkgs).notifyAddresses
      else
        [(spec fakePkgs).contactEmail];

    /**
     * if stable, then the job attribute is by convention ${attrPrefix}Stable.
     * if not stable, then ${attrPrefix}Unstable.
     */
    jobAttr = spec : stable :
      if stable then
        (spec fakePkgs).attrPrefix + "Stable"
      else
        (spec fakePkgs).attrPrefix + "Unstable";

    /**
     * The svn input is by convention ${attrPrefix}Checkout.
     *
     * The package description must have an svn attribute set
     * with attributes for the variant.
     */
    svnInputAttr = spec : variant :
      { name =
          (spec fakePkgs).attrPrefix + "Checkout";

        value =
          svnInput (builtins.getAttr variant (spec fakePkgs).svn);
      };

    svnInputs = spec : variant :
      builtins.listToAttrs [(svnInputAttr spec variant)];

    /**
     * The info attribute name is by convention ${attrPrefix}Info
     */
    infoInputAttr = spec : makeInfoURL :
      { name = (spec fakePkgs).attrPrefix + "Info";
        value = makeInfoURL spec;
      };

    requiresInputs = spec : makeInfoURL :
      builtins.listToAttrs (
        map (somespec : (reflect.infoInputAttr somespec makeInfoURL)) (requiresClosure spec)
      );

    /**
     * Take the closure of requirements.
     */
    requiresClosure = spec :
      let closure = somespec :
            (somespec fakePkgs).requires;
/*
            ++ (fun.concatLists
                  (map (x : closure (x {})) (somespec fakePkgs).requires)
               ); */
       in (closure spec);

/*
          ++ (fun.concatLists
                  (map (x : closure (x {})) (spec fakePkgs).svnRequires)
             )
          ++ (spec fakePkgs).svnRequires; */

    /**
     * Is the second argument spec required by the spec?
     */
    isRequired = byspec : somespec :
      fun.elem somespec (requiresClosure byspec);
  };

  /**
   * Taken from the nixpkgs library.
   */
  fun = rec {
    elem = x: list: fold (a: bs: x == a || bs) false list;

    fold = op: nul: list:
      if list == []
        then nul
      else op (builtins.head list) (fold op nul (builtins.tail list));

    concatLists =
      fold (x: y: x ++ y) [];
  };
}