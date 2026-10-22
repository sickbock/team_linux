################################################################################
# Create a local group to contain all users allowed to login using SSH
# Note: This is a workaround, needed when implementing SSH-based HBAC for
#   remote accounts when using AD with Unix attributes (i.e. the SSSD 
#   setting 'ldap_id_mapping = false)
# 
# Note: As soon as HBAC is implemented using host groups and SSSD SSH 
#   configuration can be re-integrated in adjoin and this group can go
################################################################################
class team_linux::profile::ssh_dummygroup inherits team_linux::profile::parameters {

  if $ipaclient == false and $joinad == false and $noderole != 'ipaserver' {
    notify {"This system has'nt any central user management and HBAC by team_linux::profile::ssh_dummygroup will be incomplete":}
  }

  # The following is wrong, a local group with remote accounts!
  $sshdummy = lookup({ name => 'team_linux::usergroups::sshdummy', default_value => 'sshdummy' })
  #$sshdummy_id = lookup({ name => 'team_linux::groups::sshdummy_id', default_value => 666 })
  $sshdummy_id = lookup({ name => 'team_linux::groupdata::sshdummy::gid', default_value => 666 })

  # lookup all users allowed to login using SSH
  #$admins = lookup({ name => 'team_linux::sudo_root', merge => 'deep', default_value => undef  })
  ####$admins = lookup({ name => 'team_linux::sudo_root', merge => 'unique', default_value => undef  })
  #$mortals = lookup({ name => 'team_linux::ssh_access', merge => 'deep', default_value => undef  })
  ##$mortals = lookup({ name => 'team_linux::ssh_access', merge => 'unique', default_value => undef  })

  #notify {"Contents of mortals is: ${mortals}":}
  #notify {"Contents of admins is: ${admins}":}
  #notify {"Contents of admin_users is: ${admin_users}":}
  #notify {"Contents of otherssh is: ${otherssh}":}

  # $ssh_users moved to general parameters.pp
  #if ( $admins != undef and $mortals != undef ) {
  #  $ssh_users = $mortals + $admins
  #} elsif $admins != undef {
  #  $ssh_users = $admins
  #} else {
  #  fail("One of 'team_linux::sudo_root' or 'team_linux::ssh_access' is undefined!")
  #}

  # transform the access_accounts array into a string suitable for sshd AllowUsers
  #$ssh_users_join = join($ssh_users,' ')

#  # https://serverfault.com/questions/416254/adding-an-existing-user-to-a-group-with-puppet
#  for ...
#    @user { "${virtuser}":
#      User <| title == "${virtuser} |> { groups +> "${sshdummy}" }
#    }
#  }

  if $ipaclient == false and $joinad == true {
    # Make sure old group is gone
    group{ 'del_sshallow':
      name    => 'sshallow',
      ensure  => absent,
    }

    group{ "${sshdummy}":
      name    => "${sshdummy}",
      ensure  => present,
      gid     => $sshdummy_id,
      members => $ssh_users,
    }
  }

}
