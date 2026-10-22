class team_linux::profile::firewalld inherits team_linux::profile::parameters {
  $disable_firewalld = lookup({ name => 'team_linux::disable_firewalld', value_type => Boolean, merge => 'deep', default_value => false })

  if $rhelmajor  >= 9 and $disable_firewalld {
    if ! defined(Package[firewalld]) {
      package{ 'firewalld':
        ensure => present,
      }
    } ->
    service{ 'firewalld.service':
      name   => 'firewalld',
      ensure => 'stopped',
      enable => 'mask',
    }
  }

}
