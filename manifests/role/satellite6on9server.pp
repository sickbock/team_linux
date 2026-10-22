################################################################################
# Implement role or complain about missing requirements
################################################################################
class team_linux::role::satellite6on9server inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {

    require team_linux::meta_profile::baseline
    contain team_linux::profile::satellite6on9server

    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 9 {
      if $facts['disks']['sdb'] and $facts['disks']['sdc'] {

        Class['::team_linux::meta_profile::baseline'] ->
        Class['team_linux::profile::satellite6on9server']

        # Keep Jan Marten happy ... for the time being
        file {'/var/lib/provisioning':
          ensure => directory,
        } ->
        file {'/var/lib/provisioning/state':
          content => 'ready',
        }

      } else {
        # one or more prerequisites failed, log
        if ! $facts['disks']['sdb'] or ! $facts['disks']['sdc'] {
          fail ( "Data disk(s) sdb and/or sdc  not found, skipping install of $cmdb['role']" )
        }
      }
    } else {
      fail( "This role requires RHEL 9 or later" )
    }

  }

}

