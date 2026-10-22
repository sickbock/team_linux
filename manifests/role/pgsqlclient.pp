################################################################################
# Q&D test dnf module wit PostgreSQL client
################################################################################
class team_linux::role::pgsqlclient inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline

    package { 'Enable dnf module postgresql':
      ensure      => '12',
      name        => postgresql,
      enable_only => true,
      provider    => 'dnfmodule',
    } ->
    package { 'Install PostgreSQL client package postgresql':
      ensure      => installed,
      name        => postgresql,
      enable_only => true,
      provider    => 'dnf',
    }


  }

}

