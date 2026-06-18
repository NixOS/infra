{
  # reboot every sunday between 00:00 and 03:00
  launchd.daemons.reboot = {
    script = ''
      date
      /sbin/shutdown -r "+$(( $RANDOM % ( 3 * 60 ) ))"
    '';
    serviceConfig = {
      StartCalendarInterval = [
        {
          Hour = 0;
          Minute = 0;
          Weekday = 0;
        }
      ];
      StandardErrorPath = "/var/log/reboot.log";
      StandardOutPath = "/var/log/reboot.log";
    };
  };
}
