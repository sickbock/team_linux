################################################################################
# Manage the sshd_config file. Note this profile uses two templates
#   - the first template used to be part of the "adjoin" module and provides
#     the core SSH server configuration
#   - the second part is used as a tempary solution to abuse SSH for
#     implementing HBAC (both originally were part of "linuxaccess")
# Note: As soon as HBAC is implemented using host groups and SSSD SSH 
#   configuration can be re-integrated in adjoin
################################################################################
class team_linux::profile::sshd_config_9 inherits team_linux::profile::parameters {

  # Originally in adjoin:
  $password_authentication = lookup({ name => 'adjoin::params::password_authentication', value_type => String, merge => 'deep', default_value => 'yes' })
  $ssh_challenge_response  = lookup({ name => 'adjoin::params::ssh_challenge_response', value_type => String, merge => 'deep', default_value => 'yes' })
  #$ssh_forwarding = lookup({ name => 'adjoin::params::ssh_forwarding', value_type => String, merge => 'deep', default_value => 'no' })
  # following parameter is used in adjoin module
  $ssh_agent_forwarding = lookup({ name => 'adjoin::params::ssh_agent_forwarding', value_type => String, merge => 'deep', default_value => 'no' })
  $sshauthkbasedir = lookup({ name => 'adjoin::params::sshauthkbasedir', value_type => String, merge => 'deep', default_value => '/etc/ssh/authorized_keys' })
#  $ssh_forwarding = lookup({ name => 'team_linux::ssh_forwarding', merge => 'deep', default_value => undef })
  $tcpkeepalive = lookup({ name => 'adjoin::params::tcpkeepalive', value_type => String, merge => 'deep', default_value => 'yes' })
  $clientaliveinterval = lookup({ name => 'adjoin::params::clientaliveinterval', value_type => String, merge => 'deep', default_value => '0' })
  $clientalivecountmax = lookup({ name => 'adjoin::params::clientalivecountmax', value_type => String, merge => 'deep', default_value => '3' })
  $userconfig = lookup({ name => 'team_linux::sshd_userconfig', merge => 'deep', default_value => undef })
  $root_login = lookup({ name => 'team_linux::root_login', value_type => Boolean, merge => 'first', default_value => true })
  # Test # notify { "User configurtion in SSH: ${userconfig}" : }

  if $root_login {
     $permitroot = "yes"
  } else {
     $permitroot = "no"
  }

  if ! defined(Service['sshd']) {
    if ! defined(Package['openssh-server']) {
    package { 'openssh-server':
        ensure => installed,
      }
      service {'sshd':
        ensure => running,
        enable => true,
      }
    }
  }

  if $ssh_forwarding == yes {
    if !defined(Package['xorg-x11-xauth']) {
      package{ "xorg-x11-xauth":
        ensure => installed,
      }
    }
    file_line { 'AllowTcpForwarding':
      ensure  => present,
      line    => "AllowTcpForwarding yes",
      path    => '/etc/ssh/sshd_config',
      match   => '^AllowTcpForwarding.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['sshd'],
    }
    file_line { 'X11Forwarding':
      ensure  => present,
      line    => "X11Forwarding yes",
      path    => '/etc/ssh/sshd_config',
      match   => '^X11Forwarding.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['sshd'],
    }
  }
    # Configure rootlogin
  if $permitroot == 'yes' {
    exec { 'configure_alternate_home':
      command => "sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config",
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
      provider => 'shell',
      unless  => "egrep -i '^PermitRootLogin.*yes' /etc/ssh/sshd_config",
      notify  => Service['sshd'],
    }
  } else {
    exec { 'configure_alternate_home':
      command => "sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config",
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
      provider => 'shell',
      unless  => "egrep -i '^PermitRootLogin.*no' /etc/ssh/sshd_config",
      notify  => Service['sshd'],
    }
  }
#    file_line { 'PermitRootLogin':
#      ensure  => present,
#      path    => '/etc/ssh/sshd_config',
#      match   => '^PermitRootLogin .*',
#      multiple => true,
#      after   => '^LoginGraceTime .*',
#      line    => "PermitRootLogin ${permitroot}",
#      notify  => Service['sshd'],
#    }
#    file_line { 'PermitRootLogin':
#      ensure  => present,
#      line    => "PermitRootLogin ${permitroot}",
#      path    => '/etc/ssh/sshd_config',
#      match   => '^PermitRootLogin.*',
#      after   => '#LoginGraceTime.*',
#      replace => true,
#      multiple => false,
#      replace_all_matches_not_matching_line => true,
#      notify  => Service['sshd'],
#    }


  # IPA SSH public key support:
    #multiple => true,
  file_line { 'AuthorizedKeysCommand':
    ensure  => present,
    line    => 'AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys',
    path    => '/etc/ssh/sshd_config',
    match   => '^AuthorizedKeysCommand .*', # note, white space needed! 
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Service['sshd'],
  }

  file_line { 'AuthorizedKeysCommandUser':
    ensure  => present,
    line    => "AuthorizedKeysCommandUser nobody",
    path    => '/etc/ssh/sshd_config',
    match   => '^AuthorizedKeysCommandUser.*',
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Service['sshd'],
  }

  file_line { 'AuthorizedKeysFile':
    ensure  => present,
    line    => "AuthorizedKeysFile /etc/ssh/authorized_keys/%u/.ssh/authorized_keys",
    path    => '/etc/ssh/sshd_config',
    match   => '^AuthorizedKeysFile.*',
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Service['sshd'],
  }

  file_line { 'ClientAliveInterval':
    ensure  => present,
    line    => 'ClientAliveInterval 15',
    path    => '/etc/ssh/sshd_config',
    match   => '^ClientAliveInterval.*',
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Service['sshd'],
  }

  file_line { 'ClientAliveCountMax':
    ensure  => present,
    line    => 'ClientAliveCountMax 3',
    path    => '/etc/ssh/sshd_config',
    match   => '^ClientAliveCountMax.*',
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Service['sshd'],
  }

  file_line { 'MaxAuthTries':
    ensure  => present,
    line    => 'MaxAuthTries 4',
    path    => '/etc/ssh/sshd_config',
    match   => '^MaxAuthTries.*',
    replace => true,
    replace_all_matches_not_matching_line => true,
    notify  => Service['sshd'],
  }

  
#  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {
#    file{ '/etc/sysconfig/sshd':
#      notify  => Service['sshd'],
#      owner   => root,
#      group   => root,
#      mode    => '0640',
#      content => template(
#        'team_linux/sysconfig_sshd.erb'
#      ),
#      require => Package['openssh-server'],
#    }
# }  
}
