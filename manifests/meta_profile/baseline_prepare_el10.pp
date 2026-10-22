###############################################################################
# IPA specific classes, profiles an dependency orderin
###############################################################################
class team_linux::meta_profile::baseline_prepare_el10 inherits team_linux::profile::parameters {
  if $etc_facter_facts_dir == false {
    contain team_linux::profile::external_facts
  } elsif String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) >= 10 {

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
      #contain team_linux::profile::localaccount       # conflicts whith exixting users & systemuserpubkeys uses different path
      #contain team_linux::profile::systemuserpubkeys  # To do: new path
      contain team_linux::profile::systemusersudo
      contain team_linux::profile::zabbix_agent2
      contain linuxbeheerscripts
      contain splunkuniversalforwarder

      if $noderole != rsyslogserver {
        contain team_linux::profile::rsyslog
      }

    # no explicit depencency order:
      contain team_linux::profile::rootpw
      #contain team_linux::profile::colorprompt # replaced by Ansible role
      #contain team_linux::profile::postfix # configured by Ansible
      contain team_linux::profile::services
      #contain team_linux::profile::ntp # disable for now, reconsider
      contain team_linux::profile::issuemotd
      contain team_linux::profile::auditd
      #contain team_linux::profile::disablethp # oracle? splunk? disable for now 
      contain team_linux::profile::manage_conditional_services # cups, avahi for oracle?
      contain team_linux::profile::start_inactive_services
      contain team_linux::profile::logrotate
      #contain team_linux::profile::qlsagent  # disable for now 
      contain team_linux::profile::firewalld

      contain team_linux::profile::selinux_config
      #contain team_linux::profile::manage_ca_trust # already in image, disable for now
 
      contain team_linux::profile::systemd_journald
      #contain team_linux::profile::dsagent         # disable for now

      Class['team_linux::profile::packages'] ->
      Class['team_linux::profile::external_facts'] ->
      Class['team_linux::profile::resolving'] ->
      Class['team_linux::profile::netmounts'] #->

#      Class['team_linux::profile::localaccount'] ->
#      Class['team_linux::profile::systemuserpubkeys']

#      Class['team_linux::profile::localaccount'] ->
#      Class['team_linux::profile::systemusersudo']

#      Class['team_linux::profile::localaccount'] ->
#      Class['team_linux::profile::zabbix_agent2']

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

      # Fix EL 10 annoyances
      file { '/usr/bin/egrep':
        ensure  => link,
        target  => '/usr/bin/grep',
      }

  } else {
    fail ( "This role requires RHEL 10 or later" )
  }
}
