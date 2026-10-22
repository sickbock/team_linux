class team_linux::profile::issuemotd inherits team_linux::profile::parameters {
  $specialmessage = lookup( { name => "team_linux::specialmessage", default_value => undef } )
  $taintedkernel = String($facts['tainted']).chomp()
  #notify { "Fact ${facts['tainted']}X" :}
  #notify { "string ${taintedkernel}Y" :}

  if "${taintedkernel}X" =~ "0X" {
    file { '/etc/motd':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('team_linux/motd.erb'),
    }
  } else {
    file { '/etc/motd':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template(
        'team_linux/motd.erb',
        'team_linux/tainted.erb'
      ),
    } 
  }
  file{ '/etc/issue':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('team_linux/etcissue.erb'),
  }
  file{ '/etc/issue.net':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('team_linux/etcissue.erb'),
  }
}
