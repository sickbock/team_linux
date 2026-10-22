################################################################################
# Implement role or complain about missing requirements
################################################################################
class team_linux::role::zabbix7server inherits team_linux::profile::parameters { 
#  if ( $facts['role'] == undef or $facts['team'] == undef ) {
#    contain team_linux::profile::external_facts
#  } else {

    require team_linux::meta_profile::baseline
    contain team_linux::profile::zabbix7server
    contain team_linux::profile::zabbix7server_conf
    contain team_linux::profile::postgreshiera
    contain team_linux::profile::postgresql_conf


    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 9 {
      if $facts['disks']['sdb'] and $facts['disks']['sdc'] {

        Class['::team_linux::meta_profile::baseline'] ->
        Class['team_linux::profile::zabbix7server'] ->
        Class['team_linux::profile::postgreshiera'] ->
        Class['team_linux::profile::postgresql_conf'] ->
        Class['team_linux::profile::zabbix7server_conf'] # ->
        #Class['team_linux::profile::zabbix_timescaledb_conf'] # ->

      } else {
        # one or more prerequisites failed, log
        if ! $facts['disks']['sdb'] or ! $facts['disks']['sdc'] {
          fail ( "Data disk(s) sdb and/or sdc  not found, skipping install of $cmdb['role']" )
        }
      }
    } else {
      fail( "This role requires RHEL 9 or later" )
    }

#  }

}

