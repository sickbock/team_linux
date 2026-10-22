class team_linux::role::opentunneldmz {
  if ( $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline

    if ! defined(Package['java-1.8.0-openjdk.x86_64']) {
      package{ 'java-1.8.0-openjdk.x86_64':
        ensure => present,
      }
    }
    if ! defined(Package['nmap-ncat']) {
      package{ 'nmap-ncat':
        ensure => present,
      }
    }


    class {'::team_linux::profile::provisioning_ready':
#        File['/etc/hosts'],
      require => [
        File['/etc/resolv.conf'],
        File['/etc/motd'],
        File['/etc/profile.d/commonprofile.sh'],
      ],
    }

    Class['team_linux::meta_profile::baseline'] ->
    Class['::team_linux::profile::provisioning_ready']

  }

}
