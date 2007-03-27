# Buildfarm configuration for the TUD buildfarm.

# The following makes it easy to build a supervisor that uses a
# different current-load directory.  This is to prevent one-shot jobs
# from failing due to all machines being in use by the "main"
# supervisor.  To build:
# 
# $ nix-build ./st-lab.nix --arg currentLoadDir \"/tmp/current-load\" -o tmp-supervisor
{currentLoadDir ? "/home/buildfarm/buildfarm-state/current-load"}:

{
  supervisor =
    (import ../../../release/supervisor/supervisor.nix) {
      stateDir = "/home/buildfarm/buildfarm-state";
      jobsURL = https://svn.cs.uu.nl:12443/repos/trace/configurations/trunk/tud/supervisor/jobs.conf;
      machinesList = ./machines;
      pkgsPath = "/etc/nixos/nixpkgs/pkgs";
      smtpHost = "smtp.st.ewi.tudelft.nl";
      fromAddress = "TU Delft Nix Buildfarm <martin@st.ewi.tudelft.nl>";
      inherit currentLoadDir;
    };
}
