###############################################################################
# IPA specific classes, profiles an dependency orderin
###############################################################################
class team_linux::meta_profile::baseline_prepare_el9 inherits team_linux::profile::parameters {
  #if ( ! $etc_facter_facts_dir or $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
  if $etc_facter_facts_dir == false {
    contain team_linux::profile::external_facts
  } elsif String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) >= 9 {

 ##    require ::lvm # see profiles
    # profiles with dependency ordering 
      contain team_linux::profile::external_facts
      contain team_linux::profile::resolving
      contain team_linux::profile::network_config 
      #contain team_linux::profile::sysctl
      contain team_linux::profile::netmounts
      contain team_linux::profile::shellconfig
      contain team_linux::profile::packages
      contain team_linux::profile::sshd_config_9
      #contain team_linux::profile::selinuxhomedirs
      #contain team_linux::profile::addapplicationswap
      contain team_linux::profile::localaccount
      contain team_linux::profile::systemuserpubkeys
      contain team_linux::profile::systemusersudo
      contain team_linux::profile::zabbix_agent2
      #contain team_linux::profile::puppetagent
      contain linuxbeheerscripts
      contain splunkuniversalforwarder

      if $noderole != rsyslogserver {
        contain team_linux::profile::rsyslog
      }

    # no explicit depencency order:
      contain team_linux::profile::rootpw
      contain team_linux::profile::colorprompt 
      contain team_linux::profile::postfix
      contain team_linux::profile::services
      contain team_linux::profile::ntp
      contain team_linux::profile::issuemotd
      #contain team_linux::profile::mlocate
      #contain team_linux::profile::module_blacklist
      #contain team_linux::profile::scsi
      contain team_linux::profile::auditd
      #contain team_linux::profile::tmpcleanup
      contain team_linux::profile::disablethp # oracle? splunk?
      #contain team_linux::profile::httpproxyserver
      contain team_linux::profile::manage_conditional_services # cups, avahi for oracle?
      contain team_linux::profile::start_inactive_services
      contain team_linux::profile::logrotate
      contain team_linux::profile::qlsagent
      contain team_linux::profile::firewalld

      #contain team_linux::profile::cryptopolicy
      #contain team_linux::profile::openldapconf

      #contain team_linux::profile::rhel8python
      #contain team_linux::profile::oddjob_mkhomedir

      contain team_linux::profile::selinux_config
      contain team_linux::profile::manage_ca_trust
 
      contain team_linux::profile::systemd_journald
      contain team_linux::profile::dsagent

      Class['team_linux::profile::packages'] ->
      Class['team_linux::profile::external_facts'] ->
      Class['team_linux::profile::resolving'] ->
      Class['team_linux::profile::netmounts'] #->
      #Class['team_linux::profile::puppetagent']

      #Class['team_linux::profile::network_config'] ->
      #Class['team_linux::profile::selinuxhomedirs'] -> 
      #Class['team_linux::profile::opt_user_homedisk'] 

      Class['team_linux::profile::localaccount'] ->
      Class['team_linux::profile::systemuserpubkeys']

      Class['team_linux::profile::localaccount'] ->
      Class['team_linux::profile::systemusersudo']

      #Class['team_linux::meta_profile::baseline_ipa'] 
      Class['team_linux::profile::localaccount'] ->
      Class['team_linux::profile::zabbix_agent2']

      Class['team_linux::profile::zabbix_agent2'] ->
      Class['linuxbeheerscripts']

      if $noderole != rsyslogserver {
        # groups zabbix should be present ragardless of package
        Class['team_linux::profile::zabbix_agent2'] ->
        Class['team_linux::profile::rsyslog']
      }

      # correct Deep Shit misconduct - https://access.redhat.com/solutions/7109596
      exec {'fix_utab.event_permissions':
        command  => 'chmod 0644 /run/mount/utab.event && chown root:root /run/mount/utab.event',
        onlyif   => 'test -f /run/mount/utab.event',
        unless   => "[[ $(/usr/bin/stat --format '%a' /run/mount/utab.event) -eq 644 ]]",
        provider => 'shell',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      }

  } else {
    fail ( "This role requires RHEL 9 or later" )
  }
}
