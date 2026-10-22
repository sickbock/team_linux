################################################################################
# Implement role or log missing requirements
################################################################################
class team_linux::role::axway inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline
    contain team_linux::profile::axway

    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 8 {
      if $facts['disks']["$appdisk"] != undef {

        Class['::team_linux::meta_profile::baseline'] ->
        Class['team_linux::profile::axway']

      } else {
        # one or more prerequisites failed, log
        if $facts['disks']["$appdisk"] == undef { notify{ "Data disk $appdisk not found, skipping install of $cmdb['role']": } }
      }
    } else {
      fail( "This role requires RHEL 8 or later" )
    }

  }

}

