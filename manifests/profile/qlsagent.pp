class team_linux::profile::qlsagent inherits team_linux::profile::parameters {

  
  if $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major']  >= '8' {
    $installqlsagent = lookup({ name => 'team_linux::installqlsagent', merge => 'first', default_value => false })
    $qualysthreads = lookup({ name => 'team_linux::qualysthreads', merge => 'first', default_value => '15' })
    if $installqlsagent == true {
      $all_repos  = $facts['repositories'].keys()
      $qlsagent_nonsup =  $all_repos.filter | $repoarray | { $repoarray =~ '^CAK_Qualys_Qualys_Cloud_Agent.*' }
      $qlsagent_nonsupname = $qlsagent_nonsup[0]
#      notify {"Qualys Cloud Agent repository: $qlsagent_nonsupname":}
      $qlsagent_repostatus = $facts['repositories'][$qlsagent_nonsupname]
#      notify {"Qualys Cloud Agent repository status: $qlsagent_repostatus":}
      
      if $qlsagent_repostatus == 'disabled' {
        notify {"Enabling Qualys Cloud Agent repository: $qlsagent_nonsupname":}
        exec { 'enable_qlsagent_repo':
          command => "subscription-manager repos --enable ${qlsagent_nonsupname}",
          path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
          provider => 'shell',
        }
      }
      package{ 'qualys-cloud-agent':
        ensure => present
      }
      exec { 'configure_qualys':
        unless    => 'test -f /etc/qualys/hostid', # or check for UseSudo=1 present in /etc/qualys/cloud-agent/qualys-cloud-agent.conf
        onlyif    => ['test -f /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh', 'id -u qlsagent >/dev/null 2>&1'],
        command   => '/usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh UseSudo=1 User=qlsagent ActivationId=7165a985-2fd2-4f30-adf5-1396c0285ff4 CustomerId=6a6a40be-df48-c0c7-801e-20e364da2921 ServerUri=https://qagpublic.qg1.apps.qualys.eu/CloudAgent/ && systemctl restart qualys-cloud-agent', 
        path      => '/usr/local/qualys/cloud-agent/bin:/bin',
        provider  => 'shell',
      }   
    }
#    file { [ '/etc/aliases.db', ]:
#      ensure  => file,
#      replace => 'no',
#      owner   => 'root',
#      group   => 'root',
#      mode    => '0644',
#      content => inline_epp("Wie dit leest is gek!\n"),
#    }  
    file { [ '/etc/aliases.db', ]:
      ensure  => present,
      replace => 'no',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source => "puppet:///modules/$module_name/aliases.db",
    }  
    file { '/etc/systemd/system/qualys-cloud-agent.service.d':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    } ->
    file { '/etc/systemd/system/qualys-cloud-agent.service.d/override.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('team_linux/qualys_agent_override.erb'),
    } ~>
    exec { 'qualys-agent-systemd-reload':
      command     => 'systemctl daemon-reload; systemctl restart qualys-cloud-agent.service',
      path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
      refreshonly => true,
    } 
  }
}
