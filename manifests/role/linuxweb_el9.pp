################################################################################
# Implement role or log missing requirements
################################################################################
class team_linux::role::linuxweb_el9 inherits team_linux::profile::parameters { 
#  if ( $facts['role'] == undef or $facts['team'] == undef ) {
#    contain team_linux::profile::external_facts # moved to baseline_el9.pp
#  } else {
    require team_linux::meta_profile::baseline
    contain team_linux::profile::linuxweb_el9

      Class['::team_linux::meta_profile::baseline'] ->
      Class['team_linux::profile::linuxweb_el9']

#  }

}

