###############################################################################
# 
# Basic Linux server configuration: to be consumed by 
#   - basesline_puppetagent profile for IAAS server role "baseline"
#   - prepare_pe_master profile (puppet-master needs different agent config)
#
################################################################################
class team_linux::meta_profile::baseline_prepare_el8 inherits team_linux::profile::parameters {

  if ( $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
    contain team_linux::profile::external_facts
  } else {

   contain team_linux::meta_profile::baseline_el8
   contain team_linux::meta_profile::baseline_ipa
   contain team_linux::meta_profile::baseline_ad 
   contain team_linux::profile::zabbix_agent2
   contain team_linux::profile::opt_user_homedisk
#   notify {"Role: ${noderole}":}
#    if $noderole != puppetpe_master and $noderole != puppetce_master {
#      contain linuxbeheerscripts
#   }
   contain linuxbeheerscripts
   contain splunkuniversalforwarder

   if $noderole != rsyslogserver {
     contain team_linux::profile::rsyslog
   }

   Class['team_linux::meta_profile::baseline_el8'] ->
   Class['team_linux::meta_profile::baseline_ipa']

   Class['team_linux::meta_profile::baseline_el8'] ->
   Class['team_linux::meta_profile::baseline_ad']

   Class['team_linux::meta_profile::baseline_ipa'] ->
   Class['team_linux::profile::zabbix_agent2']

   Class['team_linux::meta_profile::baseline_ad'] ->
   Class['team_linux::profile::zabbix_agent2']

   Class['team_linux::meta_profile::baseline_ipa'] ->
   Class['team_linux::profile::opt_user_homedisk']

   Class['team_linux::meta_profile::baseline_ad'] ->
   Class['team_linux::profile::opt_user_homedisk']

   if $noderole != puppetpe_master and $noderole != puppetce_master {
     Class['team_linux::profile::zabbix_agent2'] ->
     Class['linuxbeheerscripts']
   }

   if $noderole != rsyslogserver {
     # groups zabbix should be present ragardless of package 
     Class['team_linux::profile::zabbix_agent2'] ->
     Class['team_linux::profile::rsyslog']

   }
  }
}
