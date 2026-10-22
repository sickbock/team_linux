class team_linux::profile::rootpw {
  # Use fall environment specific password of fallback from params.eyaml
  $root_password = lookup({ name => 'team_linux::root_password', default_value => undef })

  # manage the root account (and password)
  user { "root_account":
    name        => "root",
    password    => "${$root_password}",
    forcelocal  => true,
    managehome  => false,
#    uid         => 0,  # counts as corrective change since ????
#    gid         => 0,  # counts as corrective change since ????
  }

}
