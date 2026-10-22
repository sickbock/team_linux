################################################################################
#
# Make sure to bring all used parameters, e.g. from team_linux::dns_servers 
#  in the local scope before using them (especially in templates)
#
################################################################################
class team_linux::profile::resolving inherits team_linux::profile::parameters {
  if defined('$resolvcf') {
    $dns_search   = lookup({ name => 'team_linux::dns_search', value_type => String, merge => 'deep', default_value => undef })
    $dns_servers  = lookup({ name => 'team_linux::dns_servers', merge => 'deep', default_value => undef })
    $dns_timeout  = lookup({ name => 'team_linux::dns_timeout', value_type => Integer, merge => 'deep', default_value => 1 })
    $dns_attempts = lookup({ name => 'team_linux::dns_attempts', value_type => Integer, merge => 'deep', default_value => 1 })
    $dns_rotate   = lookup({ name => 'team_linux::dns_rotate', value_type => Boolean, merge => 'deep', default_value => false })

    # only manage sane input
    if $dns_servers[0] != undef {
      file{ '/etc/resolv.conf':
        owner => 'root',
        group => 'root',
        mode  => '0644',
        content => template( 'team_linux/resolv.conf.erb' ),
      }
    } else {
      notify{ 'empty dnsserver array - not managing content of /etc/resolv.conf': }
    }
  }
}
