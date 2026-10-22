class team_linux::profile::start_inactive_services {
  # Some services are enabled by default but will not be started after
  # package installation, so Zabbix will alarm you about these services 
  # Therfore, make them running 

    if defined(Package['at']) {
      service{ 'atd':
        ensure => running,
        enable => true,
      }
    }

#    if defined(Package['smartmontools']) { # remove via manage_conditional_services.pp
#      service{ 'smartd':
#        ensure => running,
#        enable => true,
#      }
#    }

    if defined(Package['sysstat']) {
      service{ 'sysstat':
        ensure => stopped,
        enable => false,
      }
    }

    #see profile  netmounts.pp
    #if defined(Package['rpcbind']) {
    #  notify { "Package rpcbind is installed" :}
    #  if ! defined(Service[rpcbind]) {
    #    notify { "Configuring service rpcbind" :}
    #    service{ 'rpcbind':
    #      ensure => running,
    #      enable => true,
    #    }
    #  }
    #}
}
