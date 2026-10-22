class team_linux::profile::puppetagent inherits team_linux::profile::parameters {

  $runinterval = lookup( { name => 'team_linux::puppetagent_runinterval', value_type => String, merge => 'deep', default_value => '1800' })
  $puppetruntimeout = lookup( { name => 'team_linux::puppetagent_runtimeout', default_value => '3600' })


#  if ( $facts['os']['family'] == 'RedHat' and $rhelmajor >= 9 ) {
#    $ovx_repostatus = $facts['repositories']['CAK_VoxPupuli_openvox8_el-9_x86_64']
#    #notify {"OpenVox repository status: $ovx_repostatus":}
#    if $ovx_repostatus == 'disabled' {
#      notify {"Enabling OpenVox repository: CAK_VoxPupuli_openvox8_el-9_x86_64":}
#      exec { 'enable_zabbix_repo':
#        command => "subscription-manager repos --enable CAK_VoxPupuli_openvox8_el-9_x86_64; subscription-manager repos --disable CAK_Puppet_Puppet_8_EL_9",
#        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#        provider => 'shell',
#     }
#    }
#  }


  # make sure agent puppet.conf environment
  # matches that of ENC yaml on puppet master, to prevent
  # environment mismatch warnings.
  file{ "/etc/puppetlabs/puppet/puppet.conf":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template( 'team_linux/agent_puppet.conf.erb' ),
    notify  => Service[puppet_service],
  }

  service { 'puppet_service':
    name   => 'puppet',
    enable => true,
    ensure => running,
  }

  file { '/usr/local/bin/puppet':
    ensure  => link,
    target  => '/opt/puppetlabs/puppet/bin/wrapper.sh',
  }

  file { '/usr/local/bin/facter':
    ensure  => link,
    target  => '/opt/puppetlabs/puppet/bin/wrapper.sh',
  }

  #include puppet_enterprise
}
