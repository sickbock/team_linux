class team_linux::profile::systemd_journald inherits team_linux::profile::parameters {

  file { [ '/var/log/journal', ]:
      ensure => directory,
  } ->
  ini_setting { 'Storage':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'Storage',
    value   => 'persistent',
  } ->
  ini_setting { 'SystemMaxUse':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'SystemMaxUse',
    value   => '100M',
  } ->
  ini_setting { 'SystemKeepFree':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'SystemKeepFree',
    value   => '1G',
  } ->
  ini_setting { 'SystemMaxFileSize':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'SystemMaxFileSize',
    value   => '10M',
  } ->
  ini_setting { 'SystemMaxFiles':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'SystemMaxFiles',
    value   => '3',
  } ->
  ini_setting { 'MaxRetentionSec':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'MaxRetentionSec',
    value   => '1week',
  } ->
  ini_setting { 'SplitMode':
    ensure  => present,
    path    => '/etc/systemd/journald.conf',
    section => 'Journal',
    setting => 'SplitMode',
    value   => 'none',
  } ->
  file_line { 'Killroy_was_here':
    ensure  => present,
    line    => '# Configurations in this file are managed by Puppet',
    after   => '.*journald.conf.*',
    path    => '/etc/systemd/journald.conf',
    match   => '^# Configurations in this file are managed by Puppet',
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Exec['systemctl_restart_journald'],
  }

  exec { 'systemctl_restart_journald':
    command     => 'systemctl restart systemd-journald.service',
    refreshonly => true,
    onlyif      => 'test -d /var/log/journal',
    path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
   }

}
