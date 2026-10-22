################################################################################
# Role installs ansible-core
################################################################################
class team_linux::role::ansible_core inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline


    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 8 {
      if ! defined(Package['git']) {
        package{ 'git':
          ensure => present,
        }
      }
      if ! defined(Package['ansible-core']) {
        package{ 'ansible-core':
          ensure => present,
        }
      }

    } else {
      fail( "This role requires RHEL 8 or later" )
    }

  }

}

