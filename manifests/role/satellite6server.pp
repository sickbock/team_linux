################################################################################
# Implement role or complain about missing requirements
################################################################################
class team_linux::role::satellite6server inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {

#    $zabbxpsql = lookup({ name => 'team_linux::zabbxpsql', merge => 'deep', default_value => '13' })
#    $compvers  = String($facts['postgresmodule'])


    require team_linux::meta_profile::baseline
    contain team_linux::profile::satellite6server
#    contain team_linux::profile::zabbix6server_conf
    # make absolutely sure postgres gets installed before the component module 
    # tries to install the wrong version
    # debug # notify { "Module enabled ${facts['postgresmodule']}, requested version: ${pgsqlvers}":}
    #if "$facts['postgresmodule']X" == "${pgsqlvers}X" {
#    if "${compvers}X" == "${zabbxpsql}X" {
#      contain team_linux::profile::postgreshiera
#      contain team_linux::profile::postgresql_conf
#    }


    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 8 {
      if $facts['disks']['sdb'] and $facts['disks']['sdc'] {

        Class['::team_linux::meta_profile::baseline'] ->
        Class['team_linux::profile::satellite6server']

#        if "${compvers}X" == "${zabbxpsql}X" {
#          Class['team_linux::profile::zabbix6server'] ->
#          Class['team_linux::profile::postgreshiera']
#
#          Class['team_linux::profile::zabbix6server'] ->
#          Class['team_linux::profile::postgresql_conf']
#        }

        # Keep Jan Marten happy ... for the time being
        file {'/var/lib/provisioning':
          ensure => directory,
        } ->
        file {'/var/lib/provisioning/state':
          content => 'ready',
        }

#        Class['team_linux::profile::zabbix6server'] ->
#        Class['team_linux::profile::zabbix6server_conf']

      } else {
        # one or more prerequisites failed, log
        if ! $facts['disks']['sdb'] or ! $facts['disks']['sdc'] {
          fail ( "Data disk(s) sdb and/or sdc  not found, skipping install of $cmdb['role']" )
        }
      }
    } else {
      fail( "This role requires RHEL 8 or later" )
    }

  }

}

