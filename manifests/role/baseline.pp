class team_linux::role::baseline inherits team_linux::profile::parameters {
  contain team_linux::meta_profile::baseline
  if String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) < 9 {
    file { '/var/lib/provisioning':
      ensure => 'directory',
      mode => '0755',
      owner => 'root',
      group => 'root',
    } ->
    file { '/var/lib/provisioning/state':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => 'ready',
    }
  }
}
