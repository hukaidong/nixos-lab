{
  # Aggressive journald configuration to limit disk usage
  services.journald.extraConfig = ''
    # Retain journal entries for a maximum of 1 weeks
    MaxRetentionSec=1w

    # Limit the total size of all journal files to 10GB
    SystemMaxUse=256M

    # Compress old journal files to save space
    Compress=yes
  '';

  services.rsyslogd.enable = true;
}
