class team_linux::profile::disablethp {
  $rhelmajor  = Integer($facts['os']['release']['major'])
  $rhelfamily = $facts['os']['family'] 
  #notify {"This is team_linux::disablethp!":}
  $disablethp = lookup({ name => 'team_linux::disablethp', default_value => false })
  #notify { "Value for disablethp: $disablethp":}

  if defined('$disablethp') {
    if ( $rhelfamily == "RedHat" and $rhelmajor >= 8 ) {
      file { '/usr/local/bin/disablethp.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0554',
        content => template('team_linux/disablethp.sh.erb'),
      } ~>
      file { '/lib/systemd/system/disablethp.service':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('team_linux/disablethp.service.erb'),
      } ~>
      exec { 'disablethp-systemd-reload':
        command     => 'systemctl daemon-reload',
        path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
        refreshonly => true,
      } 
    } else { # RHEL 6 and Oracle on RHEL 7
      file{ '/etc/init.d/disablethp':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('team_linux/disablethp.erb'),
      }
    } ->
    if defined('$disablethp') {
      service{ 'disablethp':
        enable => true,
        ensure => running,
      }
    } ->
    file { ['/etc/tuned',
            '/etc/tuned/virtual-guest-nothp']:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    } -> 
    file { '/etc/tuned/virtual-guest-nothp/tuned.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('team_linux/nothp_tuned.conf.erb'),
    } ~>
    exec { 'refresh_tuned':
      command     => 'tuned-adm profile virtual-guest-nothp',
      path        => [ '/bin', '/usr/bin', '/sbin' ],
      subscribe   => File['/etc/tuned/virtual-guest-nothp/tuned.conf'],
      refreshonly => true,
      onlyif      => 'test -x /usr/sbin/tuned-adm',
    } 
  }
}
