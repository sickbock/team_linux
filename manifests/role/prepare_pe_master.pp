###############################################################################
#
# Basic Linux configuration to prepare a system to be used as Puppet-master
#
################################################################################
class team_linux::role::prepare_pe_master {
  if ( $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    contain team_linux::profile::external_facts
    contain team_linux::meta_profile::baseline
    contain team_linux::profile::prepare_pe_master

    Class['team_linux::profile::external_facts'] ->
    Class['team_linux::meta_profile::baseline'] ->
    Class['::team_linux::profile::prepare_pe_master']
  }
}
