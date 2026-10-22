###############################################################################
# - Manage global sudo configuration on the local system (also for IdM users)
# - Manage sudo rules in /etc/sudoers.users/<username> for local system accounts
#   only
# Remote users should have their sudo rules configured in IdM/IPA
################################################################################
class team_linux::profile::systemusersudo inherits team_linux::profile::parameters {

  # clean up left overs:
  file { [ '/etc/sudoers.d/00_legacy', '/etc/sudoers.d/11_zabbix', '/etc/sudoers.d/20_splunk', '/etc/sudoers.d/20_oracle', '/etc/sudoers.d/20_appsync', '/etc/sudoers.d/10_team_dba', ]:
    ensure       => absent,
  }

  if defined('$localserviceaccounts') {
    $locals          = keys($localserviceaccounts)

    # just assume package name is sudo
    if ! defined(Package[sudo]) {
      package{ 'sudo':
        ensure => installed,
      }
    }

    # Global sudo configuration
    # - Mange env_file
    # - Make sure includir is defined
    # - ...
    file { '/etc/sudo_restricted_env':
      ensure       => absent,
    }

    file { '/etc/sudo_env':
      ensure       => present,
      owner        => 'root',
      group        => 'root',
      mode         => '0440',
      content      => template('team_linux/sudo_env.erb'),
    } ->
    file { '/etc/sudoers':
      ensure       => present,
      owner        => 'root',
      group        => 'root',
      mode         => '0440',
      content      => template('team_linux/sudoers.erb'),
      validate_cmd => '/usr/sbin/visudo -cf %',
    } 

    # Create includedir
    file { '/etc/sudoers.users':
      ensure       => directory,
      owner        => 'root',
      group        => 'root',
      mode         => '0750',
    }

    # Create drop in files for local system accounts
    #notify { "Processing account ${locals} ..." : }
    if defined('$locals') {
      $locals.each | $s_logname | {
        #notify { "Processing account ${s_logname} ..." : }
        $accountdata     = $allaccountdata["$s_logname"]
        $sudodefaults    = $accountdata['sudodefaults']
        $sudorules       = $accountdata['sudorules']
        $customsudorules = $accountdata['customsudorules']
        file { "/etc/sudoers.users/${s_logname}":
          ensure       => present,
          owner        => 'root',
          group        => 'root',
          mode         => '0640',
          content      => template('team_linux/sudo_systemuser.erb'),
          validate_cmd => '/usr/sbin/visudo -cf %',
        }

      }
    }
  }
}

