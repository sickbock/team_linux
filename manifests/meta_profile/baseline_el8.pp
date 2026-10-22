###############################################################################
#
# Basic Linux server configuration: to be consumed by 
#   - basesline_puppetagent profile for IAAS server role "baseline"
#   - prepare_pe_master profile (puppet-master needs different agent config)
#   - After this profile:
#     - Identity specific dependencies and profiles for IdM or AD
#     - Final profiles to come after identity management
#     - Finish with roles in team_linux or other roles
################################################################################
class team_linux::meta_profile::baseline_el8 inherits team_linux::profile::parameters {

  if ( $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
    contain team_linux::profile::external_facts
  } else {

##    require ::lvm # see profiles
  # profiles with dependency ordering 
    contain team_linux::profile::resolving
    contain team_linux::profile::network_config 
    contain team_linux::profile::sysctl
    contain team_linux::profile::systemmounts
    contain team_linux::profile::netmounts
    contain team_linux::profile::shellconfig
    contain team_linux::profile::packages
    contain team_linux::profile::sshd_config
    contain team_linux::profile::repartitionrhel7boot
    contain team_linux::profile::dsagent
    contain team_linux::profile::selinuxhomedirs
    contain team_linux::profile::addapplicationswap

  # no explicit depencency order:
    contain team_linux::profile::rootpw
    contain team_linux::profile::colorprompt 
    contain team_linux::profile::postfix
    contain team_linux::profile::services
    contain team_linux::profile::ntp
    contain team_linux::profile::issuemotd
    contain team_linux::profile::mlocate
    contain team_linux::profile::module_blacklist
    contain team_linux::profile::scsi
    contain team_linux::profile::auditd
    contain team_linux::profile::repos # mainly CentOS 8 profile, not EL 9!
    contain team_linux::profile::tmpcleanup
    contain team_linux::profile::disablethp
    contain team_linux::profile::httpproxyserver
    contain team_linux::profile::remove_unused_rhel7_services
    contain team_linux::profile::remove_inactive_el8_services
    contain team_linux::profile::manage_conditional_services
    contain team_linux::profile::start_inactive_services
    contain team_linux::profile::logrotate
    contain team_linux::profile::qlsagent

    contain team_linux::profile::cryptopolicy
    contain team_linux::profile::openldapconf

    contain team_linux::profile::external_facts
    contain team_linux::profile::rhel8python
    contain team_linux::profile::oddjob_mkhomedir

    contain team_linux::profile::selinux_config
    contain team_linux::profile::manage_ca_trust

    Class['team_linux::profile::packages'] ->
    Class['team_linux::profile::external_facts']

    Class['team_linux::profile::external_facts'] ->
    Class['team_linux::profile::network_config']

    Class['team_linux::profile::resolving'] ->
    Class['team_linux::profile::network_config']

    Class['team_linux::profile::repartitionrhel7boot'] ->
    Class['team_linux::profile::dsagent']

    Class['team_linux::profile::selinuxhomedirs'] -> 
    Class['team_linux::profile::opt_user_homedisk'] 


    Class['team_linux::profile::network_config'] ->
    Class['team_linux::profile::systemmounts'] 

    Class['team_linux::profile::network_config'] ->
    Class['team_linux::profile::netmounts'] 

  }

}
