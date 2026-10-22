################################################################################
# Implement role or log missing requirements
################################################################################
class team_linux::role::positworkbench inherits team_linux::profile::parameters { 
#  if ( $facts['role'] == undef or $facts['team'] == undef ) {
#    contain team_linux::profile::external_facts
#  } else {
    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 9 {

      require team_linux::meta_profile::baseline
      contain team_linux::profile::positworkbench

      Class['team_linux::meta_profile::baseline'] ->
      Class['team_linux::profile::positworkbench']

    } else {
      fail( "This role requires RHEL 9 or later" )
    }

#  }
}

