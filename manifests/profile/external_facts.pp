################################################################################
# Create external facts e.g. provide the role managed by the administration team
################################################################################
class team_linux::profile::external_facts inherits team_linux::profile::parameters {

  # restarting Puppet when ready to speed up provisioning and avoid dependency on Service[puppet]
  if $facts['os']['family'] == 'redhat' {
    case true {
      $rhelmajor == 6: {
        $refreshp = 'echo "/sbin/service puppet restart" | at now +1 minutes'
      }
      $rhelmajor > 6: {
        $refreshp = 'echo "/bin/systemctl restart puppet" | at now +1 minutes'
      }
      default: {
        $refreshp = 'echo "/etc/init.d/puppet restart" | at now +1 minutes'
      }
    }
  } else {
      $refreshp = 'echo "/etc/init.d/puppet restart" | at now +1 minutes'
  }

  if $rhelmajor < 9 {
    exec{ 'refresh_puppet_external_fact':
      command => "$refreshp",
      path        => [ '/bin', '/usr/bin', '/sbin' ],
      onlyif => "grep -v '^ready$' /var/lib/provisioning/state",
        subscribe   => File['/etc/facter/facts.d/external_facts.sh'],
        refreshonly => true,
      }
  }

  file{ '/etc/facter':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file{ '/etc/facter/facts.d':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file{ '/etc/facter/facts.d/external_facts.sh':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    replace => 'true',
    content => template('team_linux/external_facts.sh.erb'),
  }
  file{ '/etc/facter/facts.d/repolist.sh':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    replace => 'true',
    content => template('team_linux/repolist.sh.erb'),
  }
}
