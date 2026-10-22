class team_linux::role::podman {
#  if ( $facts['role'] == undef or $facts['team'] == undef ) {
#    contain team_linux::profile::external_facts
#  } else {
    require team_linux::meta_profile::baseline
    require team_linux::profile::podman

    Class['::team_linux::meta_profile::baseline'] ->
    Class['team_linux::profile::podman']
#  }
}
