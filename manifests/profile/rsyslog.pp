################################################################################
# Global rsyslog - and auditd configuration on RHEL 8 systems
################################################################################
class team_linux::profile::rsyslog inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $rhelmajor >= 7 ) {

    $rsyslogserver   = lookup({ name => 'team_linux::rsyslogserver', merge => 'deep', default_value => undef })
    $rsyslogserverca = lookup({ name => 'team_linux::rsyslogserverca', merge => 'deep', default_value => undef })
    $rsyslogcakey    = lookup({ name => 'team_linux::rsyslogcakey', merge => 'deep', default_value => undef })
    $rsyslprotocol   = lookup({ name => 'team_linux::rsyslogprotocol', merge => 'deep', default_value => 'relp' })
    $syslog_filter = lookup({ name => 'team_linux::rsyslog_msgfilter', merge => 'deep', default_value => undef })
    $rsyslog_maxmsgsz = lookup({ name => 'team_linux::rsyslog_maxmsgsz', merge => 'deep', default_value => undef })
#    $syslog_prog = lookup({ name => 'team_linux::local0_filter', merge => 'deep', default_value => undef })

    # Allow rsyslog to write corefiles core to /
    if $facts['selinux'] {
      selboolean { 'daemons_dump_core':
        persistent => true,
        value => on,
       }
    }

    if ! defined(Package[audit]) {
      package{ 'audit':
        ensure => present,
      }
    }
    if ! defined(Package[audispd-plugins]) {
      package{ 'audispd-plugins':
        ensure => present,
      }
    }
    if ! defined(Package[rsyslog]) {
      package{ 'rsyslog':
        ensure => present,
      }
    }
    if ! defined(Package[rsyslog-mmjsonparse]) {
      package{ 'rsyslog-mmjsonparse':
        ensure => present,
      }
    }
    if ! defined(Package[rsyslog-gnutls]) {
      package{ 'rsyslog-gnutls':
        ensure => present,
      }
    }
    if ! defined(Package[rsyslog-relp]) {
      package{ 'rsyslog-relp':
        ensure => present,
      }
    }
    if ! defined(Package[gnutls-utils]) {
      package{ 'gnutls-utils':
        ensure => present,
      }
    }

    file{ '/etc/rsyslog.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog.conf.erb' ),
      notify => Service['rsyslog'],
    } ~>
    file {'should_not_be_link': # Some evil software removes this directory
      path   => '/etc/rsyslog.d',
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
      notify => Service['rsyslog'],
      force  => true,
    } ->  
    file{ '/etc/rsyslog.d/local.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog_local.conf.erb' ),
      notify => Service['rsyslog'],
    } ~>
    file{ '/etc/rsyslog.d/filter.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog_filter.conf.erb' ),
      notify => Service['rsyslog'],
    } ~>
    file{ '/etc/rsyslog.d/zabbix.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog_zabbix.conf.erb' ),
      notify => Service['rsyslog'],
    }

    service{ 'rsyslog':
      ensure => running,
      require => [ Package['rsyslog'], ],
    }

    if defined('$rsyslogcakey') and ! $rsyslog_hostcert_exists {
      file { '/root/ca-key.pem':
        ensure => file,
        owner => root,
        group => root,
        mode => '0400',
        notify => Service['rsyslog'],
        content => inline_epp($rsyslogcakey),
      }
    } else { 
      #notify {"Not removing ca-key.pem" : }
      file { '/root/ca-key.pem':
        ensure => absent,
      }
    } ~>
    if defined('$rsyslogserverca') {
      file { '/etc/rsyslog.d/ca.pem':
        ensure => file,
        content => inline_epp($rsyslogserverca),
        notify => Service['rsyslog'],
      }
    } else { 
      file { '/etc/rsyslog.d/ca.pem':
        ensure => absent,
      }
    } ~>
    file{ '/etc/rsyslog.d/x509tlstemplate':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/x509tlstemplate.erb' ),
      notify => Service['rsyslog'],
    } ~>
    exec { 'generate_rsyslog_private_key':
      command => 'certtool --generate-privkey --outfile /etc/rsyslog.d/host-key.pem',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/rsyslog.d/host-key.pem',
      notify  => Service['rsyslog'],
      require => [ Package['gnutls-utils'], ],
    } ~>
    exec { 'generate_rsyslog_private_request':
      command => 'certtool --generate-request --template /etc/rsyslog.d/x509tlstemplate --load-privkey /etc/rsyslog.d/host-key.pem --outfile /etc/rsyslog.d/request.pem',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      unless  => 'ls /etc/rsyslog.d/host-cert.pem >/dev/null 2>&1',
      require => [ Package['gnutls-utils'], File['/etc/rsyslog.d/x509tlstemplate'], Exec['generate_rsyslog_private_key'], ],
    } ~>
    exec { 'generate_rsyslog_host_cert':
      command => 'certtool --generate-certificate --template /etc/rsyslog.d/x509tlstemplate --load-request /etc/rsyslog.d/request.pem --load-ca-certificate /etc/rsyslog.d/ca.pem --load-ca-privkey /root/ca-key.pem --outfile /etc/rsyslog.d/host-cert.pem ',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/rsyslog.d/host-cert.pem',
      require => [ Package['gnutls-utils'], File['/etc/rsyslog.d/x509tlstemplate'], File['/etc/rsyslog.d/ca.pem'], Exec['generate_rsyslog_private_request'], ],
    } ~>
    exec { 'remove_request':
      command  => 'rm -f /etc/rsyslog.d/request.pem',
      path     => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      onlyif   => 'ls /etc/rsyslog.d/request.pem >/dev/null 2>&1 && ls /etc/rsyslog.d/host-cert.pem 2>&1',
      require  => [ File['/etc/rsyslog.d/ca.pem'], ],
      provider => 'shell',
    } 

    # Since rsyslog doesn't always seem to set the permissions as instructed:
    file { '/var/log/monitor-critical':
      ensure => present,
      owner  => root,
      group  => zabbix,
      mode   => '0640',
    }

    file { '/var/log/monitor-error':
      ensure => present,
      owner  => root,
      group  => zabbix,
      mode   => '0640',
    }

    file { '/var/log/monitor-warning':
      ensure => present,
      owner  => root,
      group  => zabbix,
      mode   => '0640',
    }    

    file { '/var/log/insightsclient.log':
      ensure => present,
      owner  => root,
      group  => zabbix,
      mode   => '0640',
    }    

    if defined('$rsyslogserver') {
      file { '/etc/rsyslog.d/log_to_remote.conf':
        ensure => file,
        content => template( 'team_linux/rsyslog_to_remote.conf.erb' ),
        notify => Service['rsyslog'],
        require => [ 
            File['/etc/rsyslog.d/ca.pem'],
            Exec['generate_rsyslog_private_key'],
            Exec['generate_rsyslog_host_cert'],
          ],
      }
    } else {
      file { '/etc/rsyslog.d/log_to_remote.conf':
        ensure => absent,
      }
    }

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
