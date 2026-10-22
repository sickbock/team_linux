################################################################################
# collect rsyslog and audit data on RHEL 8
################################################################################
class team_linux::profile::rsyslogserver inherits team_linux::profile::parameters {

    $rsyslogserver   = lookup({ name => 'team_linux::rsyslogserver', merge => 'deep', default_value => undef })
    $rsyslogserverca = lookup({ name => 'team_linux::rsyslogserverca', merge => 'deep', default_value => undef })
    $rsyslprotocol   = lookup({ name => 'team_linux::rsyslogprotocol', merge => 'deep', default_value => 'relp' })
    $rsyslog_maxmsgsz = lookup({ name => 'team_linux::rsyslog_maxmsgsz', merge => 'deep', default_value => undef })
    $rsyslog_retention_days   = lookup({ name => 'team_linux::rsyslog_retention_days', merge => 'deep', default_value => '820' })
    $rsyslog_zip_after_days   = lookup({ name => 'team_linux::rsyslog_zip_after_days', merge => 'deep', default_value => '1' })
    $rsyslog_dirs    = lookup({ name => 'team_linux::rsyslog_dirs', merge => 'deep', default_value => ['/var/log/remote/auditd', '/var/log/remote/syslog/authpriv', '/var/log/remote/syslog/messages', ] })
 
  if ( $facts['os']['family'] == 'RedHat' and $rhelmajor >= 8 ) {

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
    if ! defined(Package[rsyslog-doc]) {
      package{ 'rsyslog-doc':
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
    if ! defined(Package[openssl-libs]) {
      package{ 'openssl-libs':
        ensure => present,
      }
    }

    if ! defined(Service[rsyslog]) {
      service{ 'rsyslog':
        ensure => running,
        require => [ Package['rsyslog'] ],
        subscribe => File['/etc/logrotate.d/syslog'],
      }
    }

    $diskdev1  = '/dev/sdb'
    $diskdev2  = '/dev/sdc'
    $vgname    = 'rsyslog-vg'
    $lvdata    = 'rsyslog-lv'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::rsyslogsize', value_type => String, merge => 'deep', default_value => '200G'  })
    $mpdata    = '/var/log/remote'

    file { [ "${mpdata}", ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775'
    }~>
    class { 'lvm':
      volume_groups => {
        "${vgname}" => {
          createonly => true,
          physical_volumes => [ "${diskdev1}", "${diskdev2}", ],
        },
      },
    } ~>
    logical_volume { "${lvdata}":
      ensure        => present,
      volume_group  => "${vgname}",
      stripes       => 2,
      stripesize    => 128,
      size          => "${szdata}",
    } ~>
    filesystem { "/dev/${vgname}/${lvdata}":
      ensure  => present,
      fs_type => "${filesys}",
    } ~>
    mount { "${mpdata}":
      name    => "${mpdata}",
      device  => "/dev/${vgname}/${lvdata}",
      fstype  => "${filesys}",
      ensure  => mounted,
    }

    file{ '/etc/rsyslog.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog.conf.erb' ),
      notify => Service['rsyslog'],
    } ~>
    file{ '/etc/rsyslog.d/local.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog_local.conf.erb' ),
      notify => Service['rsyslog'],
    }

    file{ '/etc/rsyslog.d/remotelog.conf':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/rsyslog_remotelog.conf.erb' ),
      require => [ Exec['generate_rsyslog_self_signed_CA'],  ],
      notify => Service['rsyslog'],
    }

    file{ '/etc/sysconfig/rsyslog':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/sysconfig_rsyslog.erb' ),
      notify => Service['rsyslog'],
    }

    file { [ '/etc/pki/tls/syslogca', ]:
      ensure  => directory,
      owner => root,
      group => root,
      mode => '0755',
      require => [ Package['openssl-libs'] ],
    } ~>
    file{ '/etc/pki/tls/x509catemplate':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/x509catemplate.erb' ),
      notify => Service['rsyslog'],
    } ~>
    file{ '/etc/pki/tls/x509tlstemplate':
      ensure => present,
      owner => root,
      group => root,
      mode => '0644',
      content => template( 'team_linux/x509tlstemplate.erb' ),
      notify => Service['rsyslog'],
    } ~>
    exec { 'generate_rsyslog_private_ca-key':
      command => 'certtool --generate-privkey --outfile /etc/pki/tls/syslogca/ca-key.pem',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/pki/tls/syslogca/ca-key.pem',
      require => [ Package['gnutls-utils'], File['/etc/pki/tls/syslogca'], ],
    } ~> 
    exec { 'generate_rsyslog_self_signed_CA':
      command => 'certtool --generate-self-signed --template /etc/pki/tls/x509catemplate --load-privkey /etc/pki/tls/syslogca/ca-key.pem --outfile /etc/pki/tls/syslogca/ca.pem',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/pki/tls/syslogca/ca.pem',
      require => [ Package['gnutls-utils'], File['/etc/pki/tls/x509catemplate'], ],
    } ~> 
    exec { 'generate_rsyslog_private_key':
      command => 'certtool --generate-privkey --outfile /etc/rsyslog.d/host-key.pem',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/rsyslog.d/host-key.pem',
      require => [ Package['gnutls-utils'], Package['rsyslog'], ],
    } ~> 
    exec { 'generate_rsyslog_private_request':
      command => 'certtool --generate-request --template /etc/pki/tls/x509tlstemplate --load-privkey /etc/rsyslog.d/host-key.pem --outfile /etc/rsyslog.d/request.pem',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/rsyslog.d/request.pem',
      require => [ Package['gnutls-utils'], File['/etc/pki/tls/x509tlstemplate'], ],
    } ~> 
    exec { 'generate_rsyslog_server_cert':
      command => 'certtool --generate-certificate --template /etc/pki/tls/x509tlstemplate --load-request /etc/rsyslog.d/request.pem --load-ca-certificate /etc/pki/tls/syslogca/ca.pem --load-ca-privkey /etc/pki/tls/syslogca/ca-key.pem --outfile /etc/rsyslog.d/host-cert.pem ',
      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      creates => '/etc/rsyslog.d/host-cert.pem',
      require => [ Package['gnutls-utils'], File['/etc/pki/tls/x509tlstemplate'], Exec['generate_rsyslog_self_signed_CA'], Package['rsyslog'], Exec['generate_rsyslog_private_key'], ],
    } ~>
    file{ '/etc/rsyslog.d/global.conf':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template( 'team_linux/rsyslog_global.conf.erb' ),
      require => [ Exec['generate_rsyslog_self_signed_CA'],  ],
      notify  => Service['rsyslog'],
    } 

    if defined('$rsyslogserverca') {
      file { '/etc/rsyslog.d/ca.pem':
        ensure => file,
        content => inline_epp($rsyslogserverca),
      }
    } else {
      notify {"CA certitifacte for rsyslog server not yet added to team_linux::rsyslogserverca in appropriate EYAml file":}
      file { '/etc/rsyslog.d/ca.pem':
        ensure => absent,
      }
    } ~>
    if defined('$rsyslogserver') {
      file { '/etc/rsyslog.d/log_to_remote.conf':
        ensure => file,
        content => template( 'team_linux/rsyslog_to_remote.conf.erb' ),
        notify => Service['rsyslog'],
        require => File['/etc/rsyslog.d/ca.pem'],
      }
    } else {
      file { '/etc/rsyslog.d/log_to_remote.conf':
        ensure => absent,
      }
    }

    file { '/etc/cron.daily/housekeeping.sh':
      content => template( 'team_linux/rsyslog_housekeeping.sh.erb' ),
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0554',
    }

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
