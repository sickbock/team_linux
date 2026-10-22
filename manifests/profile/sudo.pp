################################################################################
# !!!	NATIVE AD CLIENTS ONLY!	!!!
# Temporary KISS compliant sudo configuration, to manage 
#   - /etc/sudoers 
#   - host-based  sudo configurations in /etc/sudoers.d
#
#   Note: needed since the "linuxaccess" module needs to be replaced and 
#     does not know about AD groups
#   This solution should be replaced by a central solution whenever possible
################################################################################
class team_linux::profile::sudo inherits team_linux::profile::parameters {

  # simple host specific rule for AD group in /etc/sudoers.d/##_groupname:
  #$spriority = lookup({ name => 'team_linux::sudoers_d_priority', value_type => String, merge => 'deep', default_value => undef })
  #$sadgroup  = lookup({ name => 'team_linux::sudo_adgroup', value_type => String, merge => 'deep', default_value => undef })
  #$sudorole  = lookup({ name => 'team_linux::sudo_grouprole', value_type => String, merge => 'deep', default_value => undef })
  $shortname  = $facts['networking']['hostname']
  $sudo_root  = lookup({ name => 'team_linux::sudo_root', value_type => Array[String], merge => 'deep', default_value => true })

  # lookup all roles for specific groups or users
  $allsudocmd = lookup({ name => 'team_linux::sudocmd', merge => 'deep', default_value => undef  })
  
  # per user defaults
  $allsudo_defaults = lookup( { name => "team_linux::sudodefaults", merge => 'deep', default_value => undef } )
  if $allsudo_defaults != undef {
    if $allaccountdata["${t_logname}"] != undef {
      if $allsudo_defaults[$t_logname] != undef {
        $tmp = merge( $cumulate, { "${t_logname}" => $allsudo_defaults[$t_logname] } )
      } else {
        $tmp = $cumulate
      }
    }
  } 

  # just assume package name is sudo
  if ! defined(Package[sudo]) {
    package{ 'sudo':
      ensure => installed,
    }
  }

  file { '/etc/sudoers':
    ensure       => present,
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => template('team_linux/sudoers_legacy.erb'),
    validate_cmd => '/usr/sbin/visudo -cf %',
  }
  file { '/etc/sudo_restricted_env':
    ensure       => absent,
  }
  file { '/etc/sudo_env':
    ensure       => present,
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => template('team_linux/sudo_env.erb'),
  }
  file { '/etc/sudoers.users':
    ensure       => directory,
    owner        => 'root',
    group        => 'root',
    mode         => '0750',
  }

  if $joinad == true {
    file { '/etc/sudoers.d/00_legacy':
      ensure       => present,
      owner        => 'root',
      group        => 'root',
      mode         => '0640',
      content      => template('team_linux/sudo_legacy.erb'),
      validate_cmd => '/usr/sbin/visudo -cf %',
    }
  }

#  # other possible configurations can have their own template
#  if $sudogroupcmd != undef {
#    file { '/etc/sudoers.d/01_groups':
#      ensure       => present,
#      owner        => 'root',
#      group        => 'root',
#      mode         => '0640',
#      content      => template('team_linux/groupuserswitch.erb'),
#      validate_cmd => '/usr/sbin/visudo -cf %',
#    }
#  }

}
