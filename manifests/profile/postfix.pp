class team_linux::profile::postfix inherits team_linux::profile::parameters {

  $inet_interfaces = lookup({ name => "team_linux::postfix::inet_interfaces", default_value => 'localhost' })
  $mynetworks      = lookup({ name => "team_linux::postfix::mynetworks", default_value => '0.0.0.0/0' })

  # manage postfix mail forwarding
  if !defined(Package["postfix"]) {
    package{ "postfix":
      ensure => installed,
    }
  }

  file{ "/etc/postfix/main.cf":
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template( "team_linux/postfix_main.cf.erb" ),
  }

  if !defined(Service["postfix"]) {
    service{ "postfix":
      ensure => running,
      enable => true,
      require => Package["postfix"],
      subscribe => File["/etc/postfix/main.cf"],
    }
  }

}
