################################################################################
# Implement role netpeers
################################################################################
class team_linux::role::netpeers inherits team_linux::profile::parameters { 
#  if ( $facts['role'] == undef or $facts['team'] == undef ) {
#    contain team_linux::profile::external_facts
#  } else {
    require team_linux::meta_profile::baseline
    contain team_linux::profile::linuxweb_el9
    contain team_linux::profile::netpeers

      Class['::team_linux::meta_profile::baseline'] ->
      Class['team_linux::profile::linuxweb_el9'] ->
      Class['team_linux::profile::netpeers']

#  }

}

