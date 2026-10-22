################################################################################
# Implement role, set provisioning/state to ready, or log missing requirements
################################################################################
class team_linux::role::linuxweb inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline
    contain team_linux::profile::linuxweb

    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 8 and $facts['disks']["$appdisk"] != undef  {
      class { '::team_linux::profile::provisioning_ready':
        subscribe => [
          Mount['/var/www'],
        ],
      }

      Class['::team_linux::meta_profile::baseline'] ->
      Class['team_linux::profile::linuxweb']

    } else {
      fail( "This role requires an additional disk and RHEL 8 or later" )
    }

  }

}

