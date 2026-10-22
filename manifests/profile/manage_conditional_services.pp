class team_linux::profile::manage_conditional_services {
  # remove services that are enabled but inactive and not used anyway
  # disable some known services that are enabled but not started  (oracle EBS)
  # Otherwise Zabbix will alarm you about services that are not running

  $ignorepipewire = lookup({ name => 'team_linux::ignorepipewire', value_type => Boolean, merge => 'deep', default_value => false })

  # use booleans for RHEL 8 (and above?) from custom facts 
  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major'])  >= 8 {
    if $facts['loadmodules_dir'] and $facts['loadmodules_files'] {
      Service { ['loadmodules']:
        enable => 'true',
      }
    } else { 
      Service { ['loadmodules']:
        enable => 'false',
      }
    }
  } 

  # Red Hat stupidity: https://access.redhat.com/solutions/3938381
  # but the ''nfs-convert.service'' belonging to the 'nfs-utils' package
  # has 'ConditionPathExists=/etc/sysconfig/nfs'
  # Since we don't use NFS behind a firewall, disable the service
  exec {'check_presence_/etc/sysconfig/nfs':
    command => '/bin/true',
    onlyif => 'egrep "^MOUNTD_PORT=|^STATD_PORT=|^LOCKD_TCPPORT=|^LOCKD_UDPPORT=" /etc/sysconfig/nfs >/dev/null 2>&1',
    provider => 'shell',
    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
  } ->
  Service { ['nfs-convert']:
    enable => 'false',
    require  =>  Exec['check_presence_/etc/sysconfig/nfs'],
  }

  # Oracle EBS installs print (discovery) services but does not start/use them 
  exec {'disable_cups.service':
    command  => 'systemctl disable cups.service',
    onlyif   => 'test -s /etc/systemd/system/multi-user.target.wants/cups.service',
    provider => 'shell',
    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
  }

  exec {'disable_avahi-daemon.service':
    command  => 'systemctl disable avahi-daemon.service',
    onlyif   => 'test -s /etc/systemd/system/multi-user.target.wants/avahi-daemon.service',
    provider => 'shell',
    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
  }

  # Desktop services that may get installed "as dependency" and are enabled but
  # are not required on server systems without GUI 

  # mask upower for systems not running on battery power
  #   https://access.redhat.com/solutions/7002131
  # notify {"manage upower " : }
  # Puppet CE is not detecting the package upower (PE only?), workaround:
  exec {'upower_softlink':
    command => '/bin/true',
    onlyif => '/usr/bin/test -L /etc/systemd/system/graphical.target.wants/upower.service',
  }
  Service { ['upower']:
    enable  => 'mask',
    require => Exec['upower_softlink']
  }

  # Remove unneeded services and other packages from RHEL 9
  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major'])  >= 9 and ! $ignorepipewire {
    Package {'pipewire':
      ensure => absent,
    } ->
    Package {'rtkit':
      ensure => absent,
      notify => Exec['systemctl_daemon_reload_rtkitpower'],
    } 

    Package {'xdg-desktop-portal-gtk':
      ensure => absent,
    } ->
    Package {'xdg-desktop-portal':
      ensure => absent,
    } ->
    Package {'low-memory-monitor':
      ensure => absent,
      notify => Exec['systemctl_daemon_reload_rtkitpower'],
    } 

    # Following service will not be needed (and therefore not run) on virtual systems
    # Make sure no one includes smartmontools in team_linux::packages: (DBA may do such thing!)
    Package {'smartmontools':
      ensure => absent,
      notify => Exec['systemctl_daemon_reload_rtkitpower'],
    } 

    exec { 'systemctl_daemon_reload_rtkitpower':
      command     => 'systemctl daemon-reload; systemctl',
      path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
      refreshonly => true,
    }

  }

}
