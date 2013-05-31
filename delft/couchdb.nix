{pkgs, config, ...}:

let

  inherit (pkgs.lib) mkOption mkIf singleton;
  inherit (pkgs) couchdb getopt;
  modprobe = config.system.sbin.modprobe;

  couchdbUser = "couchdb";
  couchdbFlags = "-a ${couchdbCfg}";
  couchdbCfg = pkgs.writeText "couchdb.ini" ''
          [Couch]
          ConsoleStartupMsg=Apache CouchDB is starting.
          DbRootDir=${config.services.couchdb.dbRootDir}
          Port=5984
          BindAddress=127.0.0.1
          DocumentRoot=${config.services.couchdb.documentRoot}
          LogFile=${config.services.couchdb.logDir}/couchdb.log
          UtilDriverDir=${couchdb}/lib/couchdb/erlang/lib/couch-0.8.1-incubating/priv/lib
          LogLevel=info
          [Couch Query Servers]
          javascript=${couchdb}/bin/couchjs ${couchdb}/share/couchdb/server/main.js

          ${config.services.couchdb.extraIni}
        '';

  stateDir = "/var/spool/couchdb";

  wrapper = pkgs.writeTextFile {
    name = "couchdb-wrapper";
    text = ''
      #!/bin/sh
      export HOME=${stateDir}     
      export PATH=$PATH:${getopt}/bin
      ${couchdb}/bin/couchdb ${couchdbFlags}
    ''; 
    executable = true;
    destination = "/bin/couchdb";
  };

in

{
  options = {
    services.couchdb = {
      enable = mkOption {
        default = false;
        description = ''
          CouchDB
        '';
      };

      dbRootDir = mkOption {
        default = "/data/couchdb/rootdir";
        description = ''
          DbRootDir in CouchDB configuration file
        '';
      };

      documentRoot = mkOption {
        default = "/data/couchdb/documentroot";
        description = ''
          DocumentRoot in CouchDB configuration file
        '';
      };

      logDir = mkOption {
        default = "/data/couchdb/logs";
        description = ''
          Location of CouchDB log files
        '';
      };
      extraIni = mkOption {
        default = "";
	description = ''
	  Extra text to put verbatim in ini file.
	'';
      };
      extraPath = mkOption {
        default = "";
	description =''
	  Extra PATH for job
	'';
      };
    };
  };

  config = mkIf config.services.couchdb.enable {
  
    environment.systemPackages = [ couchdb ];
  
    users.extraUsers = singleton
      { name = couchdbUser;
        uid = 33;
        description = "CouchDB daemon user";
        home = stateDir;
      };

    jobs.couchdb =
      { description = "CouchDB daemon";

        startOn = "startup";
        stopOn = "shutdown";

        preStart =
          ''
            mkdir -m 0755 -p ${stateDir}
            chown ${couchdbUser} ${stateDir}

            mkdir -m 0755 -p ${config.services.couchdb.logDir}
            chown ${couchdbUser} ${config.services.couchdb.logDir}

            mkdir -m 0755 -p ${config.services.couchdb.dbRootDir}
            chown ${couchdbUser} ${config.services.couchdb.dbRootDir}

            mkdir -m 0755 -p ${config.services.couchdb.documentRoot}
            chown ${couchdbUser} ${config.services.couchdb.documentRoot}
          '';

        exec = "${wrapper}/bin/couchdb";
      };
    
  };
  
}
