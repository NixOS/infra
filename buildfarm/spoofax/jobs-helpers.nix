attrs :

rec {

    # The easy buildfarm configuration is a system based on a
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

    # urlInput turns a URL of a release into a buildfarm input,

    urlInput = easy.urlInput;

    inherit (attrs) svnInput svnInputRev pathInput;

    # Main function to make easy jobs.

    makeEasyJob = easy.makeEasyJob;

    # A more generic job. Requires more configuration though! You need
    # to specify yourself: dirName, notifyAddresses, jobAttr in
    # releases.nix, and inputs.

    makeSpoofaxJob = easy.makeSpoofaxJob;

    # Generic job function.

    makeJob = attrs.makeJob;

    # The file packages.nix describes packages, their dependencies,
    # specific platform requirements, etc.

    specs =
      (import ../../../../release/jobs/spoofax/packages.nix);

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
      unstable =
        easy.defaultMakeInfoURL;

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
              infoInput "http://releases.strategoxt.org/${packageName}/${packageName}-unstable/";

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
              infoInput "http://releases.strategoxt.org/aterm64/${packageName}-unstable/"
            else if reflect.isRequired spec specs.aterm then
              infoInput "http://releases.strategoxt.org/${packageName}-with-aterm64/${packageName}-unstable/"
            else
              infoInput "http://releases.strategoxt.org/${packageName}/${packageName}-unstable/";
    };

  spoofaxArgs = {jobFile, jobAttr, subdir} :
    [
      ("../jobs/" + jobFile)
      jobAttr
      ("/data/webserver/dist/spoofax/" + subdir)
      ("http://releases.strategoxt.org/" + subdir)
      "/data/webserver/dist/nix-cache"
      "http://buildfarm.st.ewi.tudelft.nl/releases/nix-cache"
    ];
}
