################################################################################
# Set provisioning/state to "ready" after completing Puppet onetime actions 
# - "subscribe" to required onetime actions in the role manifest
# - requires services.pp to notify the Puppet service
#
# Chicken and egg problem: /var/lib/profisioning/state needs to exist before
#   with other values for some code in use in order to work
# currently created via preinstall script
################################################################################
class team_linux::profile::provisioning_ready inherits team_linux::profile::parameters  {

  #test#notify {"This is class team_linux::profile::provisioning_ready":}
 
  # restarting Puppet when ready ... only useful to speed up provisioning?
  if $facts['os']['family'] == 'redhat' {
    case true {
      $rhelmajor == 6: {
        $refreshp = 'echo "service puppet restart" | at now +2 minutes'
      }
      $rhelmajor > 6: {
        $refreshp = 'echo "systemctl restart puppet" | at now +2 minutes'
      }
      default: {    
        $refreshp = 'echo "/etc/init.d/puppet restart" | at now +2 minutes'
      }
    }
  } else {
      $refreshp = 'echo "/etc/init.d/puppet restart" | at now +2 minutes'
  }

  file{ '/var/lib/provisioning':
    ensure => 'directory',
    mode => '0755',
    owner => 'root',
    group => 'root',
  }
  -> file{ '/var/lib/provisioning/state':
    ensure => present,
    mode     => '0644',
    owner    => 'root',
    group    => 'root',
#    require  => [
#                  File['/var/lib/provisioning'],
#                  Exec['refresh_puppet'],
#                  Exec['provisioning_ready'],
#                ],
  }
  -> exec{ 'provisioning_ready':
    command     => 'echo "ready" > /var/lib/provisioning/state',
    path        => [ '/bin', '/usr/bin', '/sbin' ],
    unless      => 'grep ready /var/lib/provisioning/state',
#    require     => [ File['/var/lib/provisioning'], ],
#    refreshonly => true,
  }
  -> exec{ 'refresh_puppet':
    command => "$refreshp",
    path        => [ '/bin', '/usr/bin', '/sbin' ],
    onlyif => "grep -v '^ready$' /var/lib/provisioning/state",
#    refreshonly => true,
  }

}
