###############################################################################
#
# Basic Linux configuration to prepare a system to be used as CE Puppet-master
#
################################################################################
class team_linux::role::prepare_ce_master inherits team_linux::profile::parameters {
  if $facts['os']['family'] == 'redhat' and $rhelmajor >= 9 and $facts['disks']["$appdisk"] != undef {
    contain team_linux::meta_profile::baseline
    contain team_linux::profile::prepare_ce_master
  } else {
    fail( "This role requires RHEL 9 or later with an additional disk" )
  }
}
