class team_linux::profile::steppingstone inherits team_linux::profile::parameters {

  # used by DBA to map database names to host names and SSH to it
  file{ "/usr/local/bin/sshdb":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content =>  template( 'linuxbeheerscripts/steppingstone/sshdb.erb'),
  }

}
