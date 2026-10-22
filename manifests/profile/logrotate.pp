class team_linux::profile::logrotate inherits team_linux::profile::parameters {
  $retain_days = lookup( { name => "team_linux::logrotate_retain_days",
                           default_value => '28' } )

  # obsolete OS-es:
  #$syslog_pidfile = lookup( { name => "team_linux::profile::rsyslog::rsyslog_pidfile", default_value => undef } )
  #$rotate_wtmp = lookup( { name => "team_linux::profile::logrotate::rotate_wtmp", default_value => undef } )
  # Needed for RHEL 7, used in template
  if $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major']  >= '6' {
    $rsyslog_pidfile = '/var/run/syslogd.pid'
    $rotate_wtmp = true
  } else {
    $rsyslog_pidfile = undef
    $rotate_wtmp = undef
  }

  if ! defined(Package[logrotate]) {
    package{ 'logrotate':
      ensure => present,
    }
  } ->
  file{ '/etc/logrotate.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    =>  '0644',
    content => template('team_linux/logrotate.conf.erb'),
  } ->
  file{ '/etc/logrotate.d/syslog':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    =>  '0640',
    content => template('team_linux/logrotate-syslog.erb'),
  }
  # done via subscribe in rsyslog.pp # notify  => Service['rsyslog'],

}
