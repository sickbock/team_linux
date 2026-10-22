################################################################################
# Manage the sshd_config file. Note this profile uses two templates
#   - the first template used to be part of the "adjoin" module and provides
#     the core SSH server configuration
#   - the second part is used as a tempary solution to abuse SSH for
#     implementing HBAC (both originally were part of "linuxaccess")
# Note: As soon as HBAC is implemented using host groups and SSSD SSH 
#   configuration can be re-integrated in adjoin
################################################################################
class team_linux::profile::sshd_config inherits team_linux::profile::parameters {
  #include stdlib

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
  # Test # notify { "User configurtion in SSH: ${userconfig}" : }

#  # Quick and Dirty fall back solution: data in code!
#  if ! $ssh_forwarding {
#    case $cmdb['role'] {
#      /^team_dba.*/: {
#        $ssh_forwarding = 'yes'
#      }
#      /^puppetmaster.*/: {
#        $ssh_forwarding = 'yes'
#      }
#      default: {
#        $ssh_forwarding = 'no'
#      }
#    }
#  }

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

  # Originally in linuxaccess, not configured in adjoin:

#  # Maybe, root login can be disabled the moment there are alternatives
#  $root_login = lookup({ name => 'team_linuxaccess::root_login', value_type => Boolean, merge => 'first', default_value => true })

  if $ssh_forwarding == yes {
    if !defined(Package['xorg-x11-xauth']) {
      package{ "xorg-x11-xauth":
        ensure => installed,
      }
    }
  }

#  # Former HBAC parts of linuxaccess:
#  # The following is needed during transition: local group with remote accounts!
#  #   (needs module puppet_gpasswd!)
#  # see team_linux::profile::ssh_dummygroup.pp
#  $sshdummy = lookup({ name => 'team_linux::groups::sshdummy', default_value => 'sshdummy' })
#
#
#
#  ##$mortals = lookup({ name => 'team_linux::ssh_access', merge => 'unique', default_value => undef  })
#  # use values from parameters.pp for all users allowed to login using SSH
#  # except for values unique to this profile:
#  $systemacc = lookup({ name => 'team_linux::ssh_svcaccounts', merge => 'unique', default_value => undef  })
#
#  if ( $admins != undef and $mortals != undef and $systemacc != undef ) {
#    $ssh_users = $admins + $mortals + $systemacc
#  } elsif ( $admins != undef and $mortals ) {
#    $ssh_users = $admins + $mortals 
#  } elsif $admins != undef {
#    $ssh_users = $admins 
#  } else {
#    fail("'team_linux::sudo_root', 'team_linux::ssh_access', and/or 'team_linux::ssh_svcaccounts' is undefined")
#  }
#
#  # transform the access_accounts array into a string suitable for sshd AllowUsers
#  $ssh_users_join = join($ssh_users,' ')

  if $joinad == true {
    # Concatenate configurations:
    file{ '/etc/ssh/sshd_config':
      notify  => Service['sshd'],
      owner   => root,
      group   => root,
      mode    => '0600',
      content => template(
        'adjoin/sshd_config.erb',
        'team_linux/sshd_config_tail.erb'
      ),
      require => Package['openssh-server'],
    }
  } else {
    file{ '/etc/ssh/sshd_config':
      notify  => Service['sshd'],
      owner   => root,
      group   => root,
      mode    => '0600',
      content => template(
        'team_linux/sshd_config.erb',
        'team_linux/sshd_config_alt_tail.erb'
      ),
      require => Package['openssh-server'],
    }
  }
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {
    file{ '/etc/sysconfig/sshd':
      notify  => Service['sshd'],
      owner   => root,
      group   => root,
      mode    => '0640',
      content => template(
        'team_linux/sysconfig_sshd.erb'
      ),
      require => Package['openssh-server'],
    }
 }  
}
