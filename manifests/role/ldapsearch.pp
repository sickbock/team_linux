class team_linux::role::ldapsearch {
  if ( $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline

    if ! defined(Package['openldap-clients']) {
      package{ 'openldap-clients':
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

    file{ '/usr/local/bin/adsearch':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template( 'linuxbeheerscripts/adsearch.bash.erb' ),
    }

    file { [ '/etc/sudoers.users/admusers', ]:
      ensure  => file,
      replace => 'yes',
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => inline_epp("admjpoutre ALL=(ALL) NOPASSWD: ALL\nadmroostendorp ALL=(ALL) NOPASSWD: ALL\n"),
    }


  }

}
