class team_linux::profile::remove_unused_rhel7_services inherits team_linux::profile::parameters {

  # remove abrt* and other unused packages + inconsistend service configuration

  #notify { "Running remove_abrt_rhel7" : }
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] < '8' ) {

#    exec {'check_presence_/var/run/abrt':
#      command => '/bin/true',
#      onlyif => '/usr/bin/test -d /var/run/abrt',
#    }
  
    # Disable the service in case it exists on the system:
    service { 'abrtd':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'abrt-xorg':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'abrt-vmcore':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'abrt-pstoreoops':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'abrtd-ccpp':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'abrtd-oops':
      ensure => 'stopped',
      enable => 'false',
    } 

    # other inconsistent RHEL 7 stuff
    service { 'systemd-readahead-replay':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'systemd-readahead-collect':
      ensure => 'stopped',
      enable => 'false',
    } -> 
    service { 'rhel-configure':
      ensure => 'stopped',
      enable => 'false',
    } -> 
    service { 'rhel-loadmodules':
      ensure => 'stopped',
      enable => 'false',
    } 

    exec { 'remove_abrt':
      command  => 'yum erase -y abrt*',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      onlyif => '/usr/bin/test -x /usr/sbin/abrtd',
      provider => 'shell',
    }


    service { 'dmraid-activation.service':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'mdmonitor.service':
      ensure => 'stopped',
      enable => 'false',
    }  

    if ! defined(Package['dmraid']) {
      exec { 'remove_dmraid':
        command  => 'yum erase -y dmraid*',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        onlyif   => '/usr/bin/test -x /sbin/dmraid',
        unless   => '/usr/bin/test -f /etc/mdadm.conf',
        provider => 'shell',
      }
    } 
    if ! defined(Package['mdadm']) {
      exec { 'remove_mdadm':
        command  => 'yum erase -y mdadm',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        onlyif   => 'test -x /usr/sbin/mdadm >/dev/null 2>&1',
        unless   => 'test -f /etc/mdadm.conf >/dev/null 2>&1',
        provider => 'shell',
      }
    }

    service { 'pmlogger_daily_report-poll.service':
      ensure => 'stopped',
      enable => 'false',
    } ->
    service { 'pmlogger_daily_report.service':
      ensure => 'stopped',
      enable => 'false',
    }  
    service { 'pmlogger.service':
      ensure => 'stopped',
      enable => 'false',
    }  
    service { 'pmod.service':
      ensure => 'stopped',
      enable => 'false',
    }  
    service { 'pmie.service':
      ensure => 'stopped',
      enable => 'false',
    }  
    service { 'pmcd.service':
      ensure => 'stopped',
      enable => 'false',
    }  

    if ! defined(Package['pcp']) {
      exec { 'remove_pcp':
        command  => 'yum erase -y pcp* python-pcp',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        onlyif   => 'test -x /usr/bin/pcp >/dev/null 2>&1',
        unless   => 'test -f /etc/cron.d/pcp-pmlogger-daily-report >/dev/null 2>&1',
        provider => 'shell',
      }
    }

  }
}
