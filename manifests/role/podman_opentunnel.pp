class team_linux::role::podman_opentunnel {
#  if ( $facts['role'] == undef or $facts['team'] == undef ) {
#    contain team_linux::profile::external_facts
#  } else {
    require team_linux::meta_profile::baseline
    require team_linux::profile::podman_opentunnel

    Class['::team_linux::meta_profile::baseline'] ->
    Class['team_linux::profile::podman_opentunnel']
#  }
}
