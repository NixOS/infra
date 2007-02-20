# Buildfarm configuration for the Utrecht buildfarm.

# The following makes it easy to build a supervisor that uses a
# different current-load directory.  This is to prevent one-shot jobs
# from failing due to all machines being in use by the "main"
# supervisor.  To build:
# 
# $ nix-build ./st-lab.nix --arg currentLoadDir \"/tmp/current-load\" -o tmp-supervisor
{currentLoadDir ? "/home/nix/buildfarm-state/current-load"}:

(import ../../release/supervisor/supervisor.nix)
  { stateDir = "/home/nix/buildfarm-state";
    jobsURL = https://svn.cs.uu.nl:12443/repos/trace/configurations/trunk/tud/supervisor/jobs.conf;
    machinesList = ./machines;
    inherit currentLoadDir;
  }
