class team_linux::profile::remove_inactive_el8_services {
  # Package microcode_ctl currently only installed on RHEL 8 => retire this profile!
  # remove services that are enabled but inactive and not used anyway
  # Otherwise Zabbix will alarm you about services that are not running

  # not needed on virtual hardware
  # https://access.redhat.com/discussions/3377001
  package { 'microcode_ctl':
    ensure => absent,      
  } 
  # see manage_conditional_services for other services
}
