################################################################################
# Note: multi-homed systems and interfaces other than eth0 are nor supported!
#
# - manage hostname in /etc/hosts and add essential servers
# - configure systems with a single network interface eth0
#   - add the gateway, nisdomain and interface to /etc/sysconfig/network 
# - To do:
#   - stop NetworkManager from manageing /etc/resolv.conf
#   - make sure DNS servers are correct in ifcfg-eth0 and /etc/resolv.conf
#
################################################################################
class team_linux::profile::network_config inherits team_linux::profile::parameters {
  # notify { "executing network_config for ${facts['networking']['primary']} with mghostsf: $mghostsf and resolvcf: $resolvcf" : }
  if $facts['os']['family'] == 'redhat' and $rhelmajor <= 8 {
    if $facts['networking']['primary'] =~ '^e.*' {
      if defined('$mghostsf') {
        # prevent zabbix DNS requests
        $zabbix_ip      = lookup({ name => 'team_linux::zabbix_ip', default_value => undef })
        $zabbix_url     = lookup({ name => 'team_linux::zabbix_url', default_value => undef })

        $rsyslogserver  = lookup({ name => 'team_linux::rsyslogserver', default_value => undef })
        $rsyslog_ip     = lookup({ name => 'team_linux::rsyslog_ip', default_value => undef })

        # Note: Puppet server(s) and Satellite are hard coded in the template for now
        # Not implemented yet: there might be some extra host defs needed
        #$extra_hosts = lookup({ name => "team_linux::etchosts_extra", default_value => undef })

        file{ '/etc/hosts':
          ensure  => present,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => template('team_linux/etchost.erb'),
        }
      }

      if defined('$resolvcf') {
        #test # notify { "Customgateway: ${facts['customgateway']}X" :}
        $customgw = String($facts['customgateway']).chomp()
        #test#notify { "Customgw: Y${customgw}X" :}
        if defined('$customgw') and  "${customgw}X" !~ '^X' {
          file{ '/etc/sysconfig/network':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('team_linux/sysconfig_network.erb'),
          }
        } else {
          notify { "Unable to determine default gateway from VMWare proviced interface config, /etc/sysconfig/network will not be managed!" : }
          exec { 'missing_gateway':
            command   => 'logger -p local3.error "missing default gateway by VMWare in network interface definition!"',
            path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            provider => 'shell',
          }
        }
      }
    } else {
      notify { "Primary interface; ${facts['networking']['primary']} is not match regex '^e.*', /etc/hosts and /etc/sysconfig/network will not be managed!" : }
    }
  }
}
