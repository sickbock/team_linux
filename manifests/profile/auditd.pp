class team_linux::profile::auditd inherits team_linux::profile::parameters {
  if ($facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '7') {

    $auditd_filter = lookup({ name => 'team_linux::auditd_msgfilter', merge => 'deep', default_value => undef })

    if ! defined(Package['audit']) {
      package{ 'audit': ensure => installed }
    }
    if ! defined(Package['audispd-plugins']) {
      package{ 'audispd-plugins': ensure => installed }
    }

    $rules_file = '/etc/audit/rules.d/00-audit.rules'
    $audit_conf_template = 'team_linux/auditd.conf.erb'

    # do a deep hiera lookup of the audit rules
    $audit_rules = lookup({name => 'team_linux::auditd_rules', merge => 'hash'})
    $rules_template = 'team_linux/00-audit.rules.erb'

    file{ '/etc/audit/auditd.conf':
      owner => root,
      group => root,
      mode  => '0640',
      content => template($audit_conf_template),
    }

    file{ '/etc/sysconfig/auditd':
      owner => root,
      group => root,
      mode  => '0640',
      content => template('team_linux/sysconfig-auditd.erb'),
    }

    file{ "${rules_file}":
      owner => root,
      group => root,
      mode  => '0640',
      notify => [ Service['auditd'], ],
      content => template($rules_template),
    }

    file{ '/etc/audit/rules.d/quiet.rules':
      owner => root,
      group => root,
      mode  => '0640',
      notify => [ Service['auditd'], ],
      content => template('team_linux/audit_quiet.rules.erb'),
    }

    if ($facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8') {
      file { '/etc/audit/plugins.d/syslog.conf':
        ensure => file,
        content => template( 'team_linux/audit_syslog_plugin.erb' ),
        notify => [ Service['auditd'], Service['rsyslog'], ],
        require => Package['audispd-plugins'],
      }
    } elsif ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '7' ) {
      file { '/etc/audisp/plugins.d/syslog.conf':
        ensure => file,
        content => template( 'team_linux/audit_syslog_plugin.erb' ),
        notify => [ Service['auditd'], Service['rsyslog'], ],
        require => Package['audispd-plugins'],
      }
    }

    service{ 'auditd':
      ensure => running,
      enable => true,
      require => [ File['/etc/audit/auditd.conf'],
                       File['/etc/sysconfig/auditd'],
                       File["${rules_file}"], ],
      # systemd does not enable "stop" out of the box
      # using the "service redirect" stops it anyway on EL 7 & 8
      # reloading rules: augenrules --check; augenrules --load
      start   => "/usr/sbin/service auditd start",
      stop    => "/usr/sbin/service auditd stop",
      #restart => "/usr/sbin/service auditd restart",
      restart => "/usr/sbin/augenrules --check ; /usr/sbin/augenrules --load",
      status  => "/usr/sbin/service auditd status",
    }

  } else {
    notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }
}
