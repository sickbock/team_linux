###############################################################################
# Manage the ssh public keys in /etc/ssh/ for local system accounts only
#   Remote users should use IdM instead or pray CAK will support SSO one day ..
################################################################################
class team_linux::profile::systemuserpubkeys inherits team_linux::profile::parameters {

  $sshauthkbasedir = lookup({ name => 'team_linux::sshauthkbasedir', default_value => '/etc/ssh/authorized_keys' })
  $sshallow_group_id = lookup({ name => 'team_linux::sshallow_group_id', default_value => 666 })
  if defined('$localserviceaccounts') {
    $locals          = keys($localserviceaccounts)
  }
  $root_ssh_keys   = lookup( {name => 'team_linux::root_localservice_keys', default_value => undef })

  # make sure the central SSH authorized_keys base dir exists and is readable
  file { "$sshauthkbasedir":
    ensure => 'directory',
    owner  => "root",
    group  => $sshallow_group_id,
    mode   => "0755",
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
  if $root_ssh_keys != undef {
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
  file { "${rauthfile}":
    ensure       => 'present',
    owner        => "root",
    group        => "root",
    mode         => "0400",
    content      => sprintf( "%s\n", join( $root_ssh_keys, "\n" ) ),
    validate_cmd => "/usr/bin/chattr -i ${rauthfile} || echo",
    require      => File[ "${rsshdir}" ],
  }


  ##################################################
  # Only other local accounts should have pub keys
  ##################################################
  if defined('$locals') {
  $locals.each | $a_logname | {
      if defined('$a_logname') {
        $accountdata = $allaccountdata["$a_logname"]
        $sshdir      = "${sshauthkbasedir}/${a_logname}/.ssh"
        $authfile    = "${sshdir}/authorized_keys"
        $sshkeys     = $accountdata['sshkeys']
        $groupset    = $accountdata['gid']
        if ! $groupset or $groupset == "" or $groupset == '""' {
          $group = $accountdata['uid']
        } else {
          $group = $groupset
        }
        if $sshkeys != undef {
          # manage ${sshauthkbasedir}/$a_logname
          file { "${sshauthkbasedir}/${a_logname}":
            ensure => 'directory',
            owner  => "root",
            group  => "$group",
            mode   => "0750",
          }
          # manage account ssh dir
          file { "${sshdir}":
            ensure  => 'directory',
            owner   => "root",
            group   => "$group",
            mode    => "0750",
            require => File["${sshauthkbasedir}/${a_logname}"],
          }
          # For accounts in 
          # "ou=Users Inactief,ou=accounts,ou=org,dc=cak-bz,dc=local"
          # we should disable the authorized_keys ...
          # To be implemented after setting hosts "userPrincipal" in AD
          file { "${authfile}":
            ensure  => 'present',
            owner   => "${a_logname}",
            group   => "$group",
            mode    => "0400",
            content => sprintf( "%s\n", join( $sshkeys, "\n" ) ),
            require => File[ "${sshdir}" ],
          }
        }
      }
    }
  }
}
