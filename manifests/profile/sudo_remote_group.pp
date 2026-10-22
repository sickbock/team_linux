################################################################################
# Temporary KISS compliant sudo configuration, to manage host-based sudo config:
#   - /etc/sudoers.d/##_group
#
#   Note: needed since the "linuxaccess" module needs to be replaced and 
#     does not know about AD groups
#   This solution should be replaced by a central solution whenever possible
################################################################################
class team_linux::profile::sudo_remote_group inherits team_linux::profile::parameters {

  $shortname = $facts['networking']['hostname']

  file{'/etc/sudoers.d/10_sudo_oracle':
    ensure       => absent,
  }
  file{'/etc/sudoers.d/10_team_linux':
    ensure       => absent,
  }
  file{'/etc/sudoers.d/10_appsync':
    ensure       => absent,
  }
  file{'/etc/sudoers.d/10_splunk':
    ensure       => absent,
  }
  file{'/etc/sudoers.d/10_oracle':
    ensure       => absent,
  }
  file{'/etc/sudoers.d/10_':
    ensure       => absent,
  }

  # See parameters.pp for lookups

  # First: Legacy Puppet solution
  if $admin_team != undef {
    $sudo_users   = $admin_users
    $sudo_role_r  = lookup({ name => "team_linux::${noderole}_sudouser", merge => 'unique', default_value => undef })
    $sudo_role_t  = lookup({ name => "team_linux::${admin_team}_sudouser", merge => 'unique', default_value => undef })
    #debug#notify{"Team: ${admin_team}, Role: ${noderole}, Users: ${sudo_users}, Role-user: ${sudo_role_r}, Team-user: ${sudo_role_t}":}
    if ( $sudo_users != undef and ( $sudo_role_r != undef or $sudo_role_t != undef ) ) {
      $lsudo_file  = "10_${admin_team}"
    }
  } else {
    $sudo_users   = undef
    $sudo_role_t  = undef
    $sudo_role_t  = undef
    $sudo_file    = undef 
  }

  # Second: localserviceaccounts containing an array "admin-access"
  # with AD groups and/or users that have SSH access 
  if defined('$localserviceaccounts') {
    # loop over the defined accounts
    keys($localserviceaccounts).each | String $logname | {
    $accountdata = $allaccountdata["$logname"]
      if $accountdata['admin-access'] {
        $sudo_users = $accountdata['admin-access']
        #notify{"user $logname has shell $accountdata['shell']":}
        #$sudo_role_g = $logname
        if $accountdata['shell'] {
          case $accountdata['shell'] { 
            '/sbin/nologin': {
              $sudo_g_command = "/bin/su -l -s /bin/bash ${logname}"
           }
            default: {
              $sudo_g_command = "/bin/su -l -s /bin/bash ${logname}"
            }
          } 
        } else {
          $sudo_g_command = "/bin/su - ${logname}"
        } 
        file { "/etc/sudoers.d/20_${logname}":
          ensure       => present,
          owner        => 'root',
          group        => 'root',
          mode         => '0640',
          content      => template('team_linux/sudo_to_localserviceaccount.erb'),
          validate_cmd => '/usr/sbin/visudo -cf %',
        }
      }
    }
  }

  # just assume package name is sudo
  if ! defined(Package[sudo]) {
    package{ 'sudo':
      ensure => installed,
    }
  }

  if $lsudo_file != undef {
    file { "/etc/sudoers.d/${lsudo_file}":
      ensure       => present,
      owner        => 'root',
      group        => 'root',
      mode         => '0640',
      content      => template('team_linux/sudo_remote_group.erb'),
      validate_cmd => '/usr/sbin/visudo -cf %',
    }
  }

}
