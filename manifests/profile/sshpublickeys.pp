###############################################################################
# Manage the ssh public keys in /etc/ssh/ for AD admin accounts 
################################################################################
class team_linux::profile::sshpublickeys inherits team_linux::profile::parameters {

  $sshauthkbasedir = lookup({ name => 'team_linux::sshauthkbasedir', default_value => '/etc/ssh/authorized_keys' })
  $sshallow_group_id = lookup({ name => 'team_linux::sshallow_group_id', default_value => 666 })
  # lookup all users with root permissions. Arrays, so use 'unique merge' to get highest prio
  $admins = lookup({ name => 'team_linux::sudo_root', merge => 'unique', default_value => undef  })
  # lookup all users allowed to login using SSH. Arrays, so use ''unique merge'' to get highest prio
  ##$mortals = lookup({ name => 'team_linux::ssh_access', merge => 'unique', default_value => undef  })
  ##$localsvcs = lookup({ name => 'team_linux::localserviceaccounts', merge => 'hash', default_value => undef })
  if defined('$localserviceaccounts') {
    $locals = keys($localserviceaccounts)
  } 
  # lookup all other non-local accounts. Hash (with/without "ensure => absent) so use 'hash merge' for highes prio
  $accounts2delete = lookup({ name => 'team_linux::accounts2delete', merge => 'hash', default_value => undef  })
  $deleteus = keys($accounts2delete)
  $other_root_keys = lookup( {name => 'team_linux::root_localservice_keys', default_value => undef })

  ## get the accountdata Hash, keyed by logname
  #$allaccountdata = lookup({name => 'team_linux::accountdata',  merge => 'deep'})
  # default management for administrators is SSH
  $root_login = lookup({ name => 'team_linux::root_login', default_value => true })

  # make sure the central SSH authorized_keys base dir exists
  file { "$sshauthkbasedir":
    ensure => 'directory',
    owner  => "root",
    group  => $sshallow_group_id,
    mode   => "0750",
  }

  ##################################################
  # array of ssh keys for account level root
  # only used when root_login = true
  ##################################################
  if $root_login == true {
    $root_ssh_keysz =  $admins.map | $t_logname | {
      if 'sshkeys' in $allaccountdata["$t_logname"] {
        join( $allaccountdata["$t_logname"]['sshkeys'], "\n" )
      } else {
        notice( "account $t_logname does not have 'sshkeys' in team_linux::accountdata")
      }
    }
    # add additional array of (localservice) accounts
    $root_ssh_keys = $root_ssh_keysz + $other_root_keys
  } else {
    $root_ssh_keys = undef
  }

  # create the directory for the root user
  file{ "${sshauthkbasedir}/root":
    ensure => directory,
    owner => root,
    group => root,
    mode => "0700",
  }
  # create the .ssh sub-directory
  $rsshdir  = "${sshauthkbasedir}/root/.ssh"
  if defined('$root_ssh_keys') {
    # manage account ssh dir
    file { "${rsshdir}":
      ensure => 'directory',
      owner  => "root",
      group  => "root",
      mode   => "0700",
    }
  }
  # manage the authorized_keys file for root
  $rauthfile = "${rsshdir}/authorized_keys"
  if defined('$root_ssh_keys') {
    file { "${rauthfile}":
      ensure       => 'present',
      owner        => "root",
      group        => "root",
      mode         => "0400",
      content      => sprintf( "%s\n", join( $root_ssh_keys, "\n" ) ),
      validate_cmd => "/usr/bin/chattr -i ${rauthfile} || echo",
      require      => File[ "${rsshdir}" ],
    }
  } else {
    file { "${rauthfile}":
      ensure       => absent,
    }
  }

  # Warn about users to be deleted that are not yet removed from active user lists
  $deleteus.each | $deleteme | {
    if ( $admins != undef and $mortals != undef ) {
      $activeusers = $mortals + $admins
    } elsif $admins != undef {
      $activeusers = $admins
    } else {
      fail("One of team_linux::sudo_root or team_linux::${admin_team}_members and/or team_linux::ssh_access is undefined")
    }
    if $deleteme in $activeusers {
      fail("Account ${deleteme} is set to absent but still in team_linux::sudo_root or team_linux::${admin_team}_members and/or team_linux::ssh_access")
    }
  }

  ##################################################
  # loop over all accounts with individual ssh keys 
  ##################################################
  if ( $admins != undef and $mortals != undef and $locals != undef and $deleteus != undef ) { 
    $allsshlogins =  unique( $admins + $mortals + $locals + $deleteus )
  } elsif ( $admins != undef and $mortals != undef and $locals != undef ) {
    $allsshlogins =  unique( $admins + $mortals + $locals )
  } elsif ( $admins != undef and $mortals != undef ) {
    $allsshlogins =  unique( $admins + $mortals )
  } elsif $admins != undef {
    $allsshlogins =  unique( $admins + $mortals )
  } else {
    fail("One of  team_linux::sudo_root or team_linux::ssh_access is undefined")
  }

  $allsshlogins.each | $a_logname | {
    if defined('$a_logname') {
    # settings for accounts that (used to) have SSH-keys
    $sshdir  = "${sshauthkbasedir}/${a_logname}/.ssh"
    $authfile = "${sshdir}/authorized_keys"
    #test#notice( "Processing account ${a_logname} ...")
    #test#notify { "Processing account ${a_logname} ...":}
    $accountdata = $allaccountdata["$a_logname"]
    if $accountdata == undef {
      if $accounts2delete["$a_logname"] != undef {
        # 'accounts2delete' at the moment only contains former AD users
        #   so they have: "ensure => 'absent'" or 'undef', no use for 'present' yet
        if $accounts2delete["$a_logname"]['ensure'] == 'absent' or $accounts2delete["$a_logname"]['ensure'] == undef {
          # remove publickeys for non-localserviceaccounts that are disabled
          #notify { "No accountdata for ${a_logname} found ... removing SSH keys":}
          if $ensure == undef {
            $ensure = 'absent'
          }
        }
      } elsif $a_logname == undef {
        # skip empty entry / display message empty list of mortals or admins without SSH-keys
        notice("No specific SSH access granted for this node" )
      } else {
        # display warning for mortals or admins without SSH-keys
        fail( "Account: $a_logname is undefined in team_linux::accountdata, add $a_logname with SSH public key" )
      }
    } else {
      # Process local and remote accounts that have "accountdata" (and SSH keys)
      if $a_logname in $locals {
        # just set localserviceaccounts to existing
        $adminexists = $a_logname
        if $ensure == undef {
          $ensure = 'present'
        }
      } elsif $a_logname in $deleteus {
        $adminexists = "removeme"
      } else {
        # check existence in AD for accounts not in $deleteus:
        # For some reasen, the following result suddenly seems to contain 
        # the Kerberos somtetimes (unknown where and why, seen on at least 
        # RHEL 7.9 clno02932)
        $adminexists=chop(generate('/bin/bash','-c',"/usr/bin/getent passwd ${a_logname} | /usr/bin/cut -d: -f1"))
        #     To display message during test-run: uncommet next line
        # notify {"lookup for user ${a_logname} returned ${adminexists}":}
        # Add really quick and dirty hard coded domain specific workaround:
        if $adminexists == "${a_logname}" or $adminexists == "${a_logname}@CAK-BZ.LOCAL" {
          $ensure = 'present'
        } else {
          #$adminexists = "removeme"
          notice("variable adminexists for $a_loginame is: $adminexists")
        }
      }
    }
    # add same workagound as above:
    if $adminexists == "${a_logname}" or $adminexists == "${a_logname}@CAK-BZ.LOCAL" {
      $sshkeys = $accountdata['sshkeys']
      if $sshkeys != undef {
        # manage ${sshauthkbasedir}/$a_logname
        file { "${sshauthkbasedir}/${a_logname}":
          ensure => 'directory',
          owner  => "root",
          group  => $sshallow_group_id,
          mode   => "0750",
        }
        # manage account ssh dir
        file { "${sshdir}":
          ensure  => 'directory',
          owner   => "root",
          group   => $sshallow_group_id,
          mode    => "0750",
          require => File["${sshauthkbasedir}/${a_logname}"],
        }
        # For accounts in 
        # "ou=Users Inactief,ou=accounts,ou=org,dc=cak-bz,dc=local"
        # we should disable the authorized_keys ...
        # To be implemented after setting hosts "userPrincipal" in AD
        file { "${authfile}":
          ensure       => 'present',
          owner        => "${a_logname}",
          group        => $sshallow_group_id,
          mode         => "0400",
          content      => sprintf( "%s\n", join( $sshkeys, "\n" ) ),
          require      => File[ "${sshdir}" ],
        }
      }
    } else {
      if $authfile != undef {
        #notify { "Deleting SSH-keys for ${a_logname}  ..." :}
        # No AD account?, clean the authorized_keys
        file { "disable_${authfile}":
          path    => "$authfile",
          ensure  => 'absent',
        }
        # remove account authorized key directory
        file { "rmdir_${sshdir}":
          path    => "$sshdir",
          ensure  => 'absent',
          force   => 'true',
        }
        # remove ${sshauthkbasedir}/$a_logname
        # skip empty entry for $a_logname
        if $a_logname != undef {
          file { "remove_${a_logname}_authkbase":
            path    => "${sshauthkbasedir}/${a_logname}",
            ensure  => 'absent',
            force   => 'true',
          }
        }
      }
    }
  }
  }
}
