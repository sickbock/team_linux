################################################################################
# Manage local accounts for services,
# "abuse" this class to disable home directories for orphaned AD accounts
#
################################################################################
class team_linux::profile::localserviceaccount inherits team_linux::profile::parameters {
  $account_locked_passwd = lookup({ name => 'team_linux::account_locked_passwd', default_value => '!!' })
  $account_shell = lookup({ name => 'team_linux:account_shell', default_value => '/bin/bash' })
  $homedir_parent = lookup({ name => 'team_linux::homedir_parent', default_value => '/home' })
  $homedir_mode = lookup({ name => 'team_linux::homedir_mode', default_value => '0700' })
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

# Moved to parameters.pp, cleanup ASAP when obsolete!
  ## establish a merged deep array of the hiera hierarchy of defined localserviceaccounts and remote accounts to disable
  #$localserviceaccounts = lookup({name => 'team_linux::localserviceaccounts', merge => 'hash'})
##  $disabledaccounts = lookup({name => 'team_linux::accounts2delete', merge => 'hash', default_value => undef })
##  if $localserviceaccounts and $disabledaccounts {
##    $accounts_merge = $localserviceaccounts + $disabledaccounts 
##  } elsif $localserviceaccounts {
##    $accounts_merge = $localserviceaccounts 
##  } else {
##    $accounts_merge =  $disabledaccounts 
##  }

#  # really uggly workaround (for RHEL 7 + AD / clnp32739 only):
#  $zabbix_agent = lookup ( { name => 'team_linux::zabbix_agent', value_type => String, merge => 'deep', default_value => 'zabbix-agent2' } )
#  if $zabbix_agent == 'zabbix-agent2' {

  if $accounts_merge != undef {

    ## get the accountdata Hash, keyed by logname
    #$allaccountdata = lookup({name => 'team_linux::accountdata',  merge => 'deep'})

    # obsolete # get the groupdata Hash, keyed by logname
    # obsolete #$allgroupdata = lookup({ name => "team_linux::groupdata",  merge => 'deep'  })

    # loop over the defined accounts
    keys($accounts_merge).each | String $logname | {

      # Set 'ensure = present' if not defined otherwise
      if $accounts_merge["$logname"] != undef {
        if $accounts_merge["$logname"]['ensure'] == undef {
          $ensure = 'present'
        } else {
          $ensure = $accounts_merge["$logname"]['ensure']
        }
      } else {
        $ensure = 'present'
      }

      # get data 'level' => 'localserviceaccount' and 'ensure' => 'absent'
      $accountdata = $allaccountdata["$logname"]
      if $accountdata == undef {
        notice( "account $logname undefined in team_linux::accountdata Please add data if this is a localserviceaccount" )
        # for non-localserviceaccounts, set default homedir to disable below
        $homedir = "/home/${logname}"
      } else {
        if $accountdata['level'] == 'localservice' {
          if $accountdata['homedir'] == undef {
            $homedir = "/home/${logname}"
          } else {
            $homedir = $accountdata['homedir']
          }
        } else { 
          # non-localserviceaccounts should not exist
          # in case of 'ensure => absent' disable the homedir (also for AD-accounts)
          if $ensure == 'absent' {
            notice("account ${logname} is ensure => absent and will be disabled")
            if $accountdata['homedir'] == undef {
              $homedir = "/home/${logname}"
            } else {
              $homedir = $accountdata['homedir']
            }
          } else {
            # other users should not exist and will not be created
            fail( "account ${logname} does not have level 'localservice' in team_linux::accountdata and will not be created" )
          }
        } 
      }


      # create localserviceaccount if ensure => present
      if $ensure == 'present' {

        # set shell for localserviceaccounts
        if $accountdata['shell'] == undef {
          #notify{"shell for ${logname} is undefined, setting to ${account_shell}":}
          $shell = $account_shell
        } else {
          #notify{"setting shell for ${logname} to $accountdata[$logname]['shell']":}
          $shell = $accountdata['shell']
        }


        # To do: something about ~/.ssh/authorized_keys?
        # Or just configure /etc/... globally

        ### localserviceaccount aanmaken ####

        # Do not let Puppet assign ID's: Give up when there no uid is assigned      
        if $accountdata['uid'] == undef {
          fail("uid for localserviceaccount $logname undefined in team_linux::accountdata.${logname}")
        } else {
          $uid = $accountdata['uid']
        }

        # Note: unlike "linuxaccess":
        #   gid should be numerical and only specified if different from UID
        #   groups should contain additional group membership(s)
        if $accountdata['gid'] == undef {
          # use next available GID: default or $logname
          #$gid = $logname
          # or set same number for GID exlicit to $uid
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
        # Workaround legacy CAK oracle configuration with non-defauld GID:
        # Debug: # notify{"Create user $logname and group $group, other groups: $groups":}
        if $logname == 'oracle' {
          # Legacy oracle user uses "already declared" group "dba"
          user { "team_linux_account_${logname}":
            name           => $logname,
            ensure         => present,
            comment        => $gecos,
            forcelocal     => true,
            managehome     => true,
            uid            => $uid,
            gid            => $gid,
            groups         => $groups,
            home           => $homedir,
            password       => $password,
            purge_ssh_keys => true,
            shell          => $shell,
            require        => Group['dba']
          }
        } elsif $logname == 'zabbix' { # make zabbix a known and managed resource
          # this stanza can be removed once UID/GID is consistent across the landscape
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
            groups         => "${groups[0]}",
            home           => "${homedir}",
            password       => "${password}",
            purge_ssh_keys => true,
            shell          => "${shell}",
            notify         => Service['zabbix-agent'],
          } #~>
#          exec {"check_${logname}_dirs":
#            command   => "chown -R ${uid}:${gid} /var/{log,run}/zabbix",
#            unless    => "stat --format=%u:%g /var/{log,run}/zabbix | egrep ${uid}:${gid}",
#            path      => ['/usr/bin','/usr/sbin','/bin','/sbin'],
#            loglevel  => 'info',
#            logoutput => 'on_failure',
#            provider  => 'shell',
#            timeout   => 0,
#          }
        } else {
          # normal user configurations require their own primary group
          # Avoid log messages about "Unknown variable: 'groups'"
          if defined('$groups') {
            group {"${group}":
              ensure  => present,
              gid     => $gid,
              #before  => User["${logname}"]
            } ->
            user { "team_linux_account_${logname}":
              name           => $logname,
              ensure         => present,
              comment        => $gecos,
              forcelocal     => true,
              managehome     => true,
              uid            => $uid,
              gid            => $gid,
              groups         => $groups,
              home           => $homedir,
              password       => $password,
              purge_ssh_keys => true,
              shell          => $shell,
              #require        => Group["${group}"]
            }
          } else {
            group {"${group}":
              ensure  => present,
              gid     => $gid,
              #before  => User["${logname}"]
            } ->
            user { "team_linux_account_${logname}":
              name           => $logname,
              ensure         => present,
              comment        => $gecos,
              forcelocal     => true,
              managehome     => true,
              uid            => $uid,
              gid            => $gid,
              home           => $homedir,
              password       => $password,
              purge_ssh_keys => true,
              shell          => $shell,
              #require        => Group["${group}"]
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

        $user_ulimits = $allaccountdata["${logname}"]['ulimits']
          #notify {"${logname} limits: ${user_ulimits}" : }
        if $user_ulimits {
          #notify {"configuring ${user_ulimits} for ${logname}" : }
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
#  }

  file { "${ulimitconf_file}":
    mode    => "${ulimitconf_mode}",
    owner   => "${ulimitconf_owner}",
    group   => "${ulimitconf_group}",
    content => template("${ulimitconf_template}"),
  }

}
