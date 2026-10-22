################################################################################
# Manage local accounts belonging to services running on the system
#  - make sure uid and gid are consistent and unique
#  - allow the systemusersudo class to manage eventual sudo rules
# All other accounts should be part of a directory service, including
# - accounts belonging to natural persons
# - accounts that do not run services (therefore are not required at boot)
#
# Limits should be configured using the systemd service. Only when the account
#   needst to be used with an interactive shell configure pam limits
#
# SSH public keys are managed in systemuserpubkeys.pp (same accounts and admins)
################################################################################
class team_linux::profile::localaccount inherits team_linux::profile::parameters {
  $account_locked_passwd = lookup({ name => 'team_linux::account_locked_passwd', default_value => '!!' })
  $homedir_mode = lookup({ name => 'team_linux::homedir_mode', default_value => '0700' })
  # Legacy database software needs some special care
  $oinstallgid = lookup({ name => 'team_linux::groupdata.oinstall.gid', default_value => '1500' })
  $dbagid = lookup({ name => 'team_linux::groupdata.dba.gid', default_value => '1501' })
  $eessigid = lookup({ name => 'team_linux::groupdata.eessi.gid', default_value => '2143' })
  # Keeu ulimit configuration for now, most likely some legacy software still requires it for shell scripting
  $add_ulimits = lookup( { name => 'team_linux::add_ulimits', default_value => undef } )
  $ulimitconf_file = lookup({ name => 'team_linux::ulimitconf_file', default_value => '/etc/security/limits.conf' })
  $ulimitconf_dir = lookup({ name => 'team_linux::ulimitconf_dir', default_value => '/etc/security/limits.d' })
  $ulimitconf_template = lookup({ name => 'team_linux::ulimitconf_template', default_value => 'team_linux/limits_conf.erb' })
  $user_limits_template = lookup({ name => 'team_linux::user_limits_template', default_value => 'team_linux/user_limits.erb' })
  $ulimitconf_mode = lookup({ name => 'team_linux::ulimitconf_mode', default_value => '0644' })
  $ulimitconf_owner = lookup({ name => 'team_linux::ulimitconf_owner', default_value => 'root' })
  $ulimitconf_group = lookup({ name => 'team_linux::ulimitconf_group', default_value => 'root' })
  $orphanedid = lookup({ name => 'team_linux::accountdata::oldhomedir::uid', default_value => 'oldhomedir' })
  $ulimit_manage = lookup({ name => 'team_linux::ulimit_manage', default_value => true })

  if $localserviceaccounts != undef {
    # replace legacy profile localgroup.pp, stand-alone groups are most
    # likely no longer required except for Oracle (all other groups should 
    #   ideally come with software packages).
    # Some database product form the 1970's requires very special care :-(
    if 'oracle' in $localserviceaccounts or 'appsync' in $localserviceaccounts or 'ap' in $localserviceaccounts {
      group { 'oinstall':
        ensure  => present,
        gid     => "${oinstallgid}",
      }~>
      group { 'dba':
        ensure  => present,
        gid     => "${dbagid}",
      }
      group { 'eessi':
        ensure  => present,
        gid     => "${eessigid}",
      }
    }

    # loop over the defined accounts
    keys($localserviceaccounts).each | String $logname | {
      #notify {"Processing: $logname":}
      # Set 'ensure = present' if not defined otherwise
      #   (no clue how $logname can be undef at this point ..)
      #   following seems to work ("vraag niet hoe het kan maar profiteer ervan!")
      if $localserviceaccounts["$logname"] != undef {
        if $localserviceaccounts["$logname"]['ensure'] == undef {
          $ensure = 'present'
        } else {
          $ensure = $localserviceaccounts["$logname"]['ensure']
        }
      } else {
        $ensure = 'present'
      }

      # get data 'level' => 'localserviceaccount' and 'ensure' => 'absent'
      $accountdata = $allaccountdata["$logname"]
      #notify {"Accountdata for $logname is: $accountdata":}
      if $accountdata == undef {
        notice( "local system account $logname undefined in team_linux::accountdata Please add the data " )
      } else {
        if $accountdata['homedir'] == undef {
          $homedir = "/home/${logname}"
        } else {
          $homedir = $accountdata['homedir']
        }
        if $ensure == 'absent' {
          notice("account ${logname} is ensure => absent and will be disabled")
          if $accountdata['homedir'] == undef {
            $homedir = "/home/${logname}"
          } else {
            $homedir = $accountdata['homedir']
          }
        } 
      }

      # create the local account if ensure => present
      if $ensure == 'present' {
        # set shell for localserviceaccounts
        if $accountdata['shell'] == undef {
          #notify{"shell for ${logname} is undefined, setting to ${account_shell}":}
          $shell = '/sbin/nologin'
        } else {
          #notify{"setting shell for ${logname} to $accountdata[$logname]['shell']":}
          $shell = $accountdata['shell']
        }

        # Do not let Puppet assign ID's: Give up when there no uid is assigned      
        if $accountdata['uid'] == undef {
          fail("uid for localserviceaccount $logname undefined in team_linux::accountdata.${logname}")
        } else {
          $uid = $accountdata['uid']
        }

        # Note: unlike the pre-historic class "linuxaccess":
        #   gid should be numerical and only specified if different from UID
        #   groups should contain additional group membership(s) only
        if $accountdata['gid'] == undef {
          $gid = $accountdata['uid']
        } else {
          $gid = $accountdata['gid']
        }

        if $accountdata['gecos'] == undef {
          $gecos = $logname
        } else {
          $gecos = $accountdata['gecos']
        }
        if $accountdata['groups'] != undef {
          $groups = unique( $accountdata['groups'] )
        }

        # in theory, this should not be needed, only accounts in a directory service have a real password, right?
        if $accountdata['password'] == undef {
          $password = $account_locked_passwd
        } else {
          $password = $accountdata['password']
        }

        # explicit user primary group
        if $accountdata['group'] == undef {
          $group = $logname
        } else {
          $group = $accountdata['group']
        }

        # Now comes the really ugly stuff where data and code are no longer separated :-(
        # Workaround legacy CAK oracle configuration with non-defauld GID:
        # or, use Oracle stype non-default configuration?
        # https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/changes-in-this-release-for-oracle-database.html
        # Debug: # notify{"Create user $logname and group $group, other groups: $groups":}
        # Note: strings (including UID and GID) may be quoted, arrays not!
        if $logname == 'oracle' {
          user { "team_linux_account_${logname}":
            name           => "${logname}",
            ensure         => present,
            comment        => "${gecos}",
            forcelocal     => true,
            managehome     => true,
            uid            => "${uid}",
            gid            => "${dbagid}",
            groups         => $groups,
            home           => "${homedir}",
            password       => "${password}",
            purge_ssh_keys => true,
            shell          => "${shell}",
            #require        => Group[$groups], #not needed, required groups created above
          }
        } elsif $logname == 'ap' {
          user { "team_linux_account_${logname}":
            name           => "${logname}",
            ensure         => present,
            comment        => "${gecos}",
            forcelocal     => true,
            managehome     => true,
            uid            => "${uid}",
#            gid            => "${gid}",
            groups         => $groups,
            home           => "${homedir}",
            purge_ssh_keys => true,
            shell          => "${shell}",
            #require        => Group[$groups], #not needed, required groups created above
          }

        } else {
          if defined('$groups') and $logname != 'ap' {
            # debug secundary group membership if needed
            #notify{"Groups: $groups":}
            #notify{"Elements in groups: ${groups.length()}":}
            #notify{"logname: $logname":}
            #notify{"Group first element: ${groups[0]}":}
            # workaround for various cases:
            #  when you need groups defined outside Puppet
            #  or you need groups belonging to other users that may not yet exist: check groups in /etc/groups
            $sortedgroups = $groups.sort
            $grepstring = $sortedgroups.join('.*')
            exec {"check_${grepstring}":
              command  => 'true',
              unless   => "sort -t: -k1 /etc/group | awk -F: '{ORS=\" \"; print}' > /tmp/\$\$ ; egrep -v \"${grepstring}\" /tmp/\$\$ >/dev/null 2>&1 ; rm -f /tmp/\$\$",
              path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
              provider => 'shell',
              loglevel  => 'info',
              logoutput => 'on_failure',
              returns   => [0,1],
            } ->
            group {"${group}": # first make sure the primary group exists
              ensure  => present,
              gid     => $gid,
            } ->
            user { "team_linux_account_${logname}":
              name           => "${logname}",
              ensure         => present,
              comment        => "${gecos}",
              forcelocal     => true,
              managehome     => true,
              uid            => "${uid}",
              gid            => "${gid}",
              groups         => $groups,
              home           => "${homedir}",
              password       => "${password}",
              purge_ssh_keys => true,
              shell          => "${shell}",
              require        => Exec["check_${grepstring}"],
            }
          # normal user configurations require their own primary group
          # Avoid log messages about "Unknown variable: 'groups'"
          } else { 
            if $uid != $gid { # stop whining over gid when not needed
              group {"${group}":
                ensure  => present,
                gid     => $gid,
              } ->
              user { "team_linux_account_${logname}":
                name           => "${logname}",
                ensure         => present,
                comment        => "${gecos}",
                forcelocal     => true,
                managehome     => true,
                uid            => "${uid}",
                gid            => "${gid}",
                home           => "${homedir}",
                password       => "${password}",
                purge_ssh_keys => true,
                shell          => "${shell}",
              }
            } else { # avoid "unneede/unwanted" corrective change:
              group {"${group}":
                ensure  => present,
                gid     => $gid,
              } ->
              user { "team_linux_account_${logname}":
                name           => "${logname}",
                ensure         => present,
                comment        => "${gecos}",
                forcelocal     => true,
                managehome     => true,
                uid            => "${uid}",
                home           => "${homedir}",
                password       => "${password}",
                purge_ssh_keys => true,
                shell          => "${shell}",
              }
            }
          } 
        }

        if $accountdata['homedirmode'] == undef {
          $hdm = $homedir_mode
        } else {
          $hdm = $accountdata['homedirmode']
        }
        # in case mode differs from the default:
        file { "enable_${homedir}":
          path   => "${homedir}",
          mode   => "${hdm}",
        }

        #notify { "Processing ulimits and homedir for ${logname}" : }
        if $os['name'] != 'CentOS' { # workaround unidentified issue
          $user_ulimits = $allaccountdata["${logname}"]['ulimits']
          if $user_ulimits {
            #notify{"User limits for ${logname}: $user_ulimits":}
            file { "${ulimitconf_dir}/${logname}.conf":
              mode    => "${ulimitconf_mode}",
              owner   => "${ulimitconf_owner}",
              group   => "${ulimitconf_group}",
              content => template("${user_limits_template}"),
            }
          } elsif ! $user_ulimits or "${user_ulimits}X" =~ '^X' {
            #notify {"unconfiguring ${user_ulimits} for ${logname}" : }
            file { "${ulimitconf_dir}/${logname}.conf":
              ensure => absent,
            }
          }
        }

      } else {
        # disable home directory for accounts "ensure => absent'
        # If the account is ensure=>absent, but the home directory still exists,
        #     change owner to "orphanedid:orphanedid" if not already done!
        exec {"check_${homedir}":
          command   => '/bin/true',
          unless    => "test ! -d ${homedir} || stat --format=%U:%G ${homedir}|egrep ${orphanedid}:${orphanedid}",
          path      => ['/usr/bin','/usr/sbin','/bin','/sbin'],
          loglevel  => "info",
          logoutput => "on_failure",
        }
        -> file { "changeowner_${homedir}":
          path    => "${homedir}",
          owner   => "${orphanedid}",
          group   => "${orphanedid}",
          recurse => true,
          force   => true,
        }
      }
    }
  }

  file { "${ulimitconf_file}":
    mode    => "${ulimitconf_mode}",
    owner   => "${ulimitconf_owner}",
    group   => "${ulimitconf_group}",
    content => template("${ulimitconf_template}"),
  }

}
