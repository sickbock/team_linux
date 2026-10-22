class team_linux::profile::tmpcleanup inherits team_linux::profile::parameters {

  if ( $facts['os']['family'] == 'RedHat' ) {

    if ( $facts['os']['release']['major'] < '7' ) {
      # just assume package name is sudo
      if ! defined(Package[tmpwatch]) {
        package{ 'tmpwatch':
        ensure => installed,
        }
      }
      file{ '/etc/cron.daily/tmpwatch':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('team_linux/tmpwatch.erb'),
      }
    }

    if ( $facts['os']['release']['major'] >= '7' ) {
      # just assume package name is sudo
      if ! defined(Package[systemd]) {
        package{ 'systemd':
        ensure => installed,
        }
      }
      file{ '/usr/lib/tmpfiles.d/oraesbtmp.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('team_linux/tmpfilesora.conf.erb'),
      }
    }

  }

}
