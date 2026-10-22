class team_linux::profile::localgroup {
  $loglevel = 'on_failure'

  #$user_groups = lookup({ name => 'team_linux::usergroups', default_value => undef })

  # For the time being: filter out: SSH dummy group (see ssh_dummygroup.pp)
  $sshdummy = lookup({ name => 'team_linux::usergroups::sshdummy', default_value => 'sshdummy' })

  $groups_mergeall = lookup({name => 'team_linux::usergroups', merge => 'deep'})
  # get all groups except sshdummy -> see ssh_dummygroup.pp
  $groups_merge = $groups_mergeall - $sshdummy #- $oinstall
#  if defined('$joinad') {
#    $groups_merge = $groups_mergeall - $sshdummy #- $oinstall
#  } else {
#    $groups_merge = $groups_mergeall #- $oinstall
#  }
  

  if $groups_merge != undef {

    # get the groupdata Hash, keyed by logname
    $allgroupdata = lookup({ name => "team_linux::groupdata",  merge => 'deep'  })

    # loop over the defined groups
    keys($groups_merge).each | String $groupname | {

      # get the data for this group
      $groupdata = $allgroupdata["$groupname"]
        if $groupdata == undef {
          fail( "group $groupname undefined in team_linux::groupdata" )
        }

      # 'ensure = present' if not defined otherwise
      if $groups_merge["$groupname"] != undef {
        if $groups_merge[$groupname]['ensure'] == undef {
          $ensure = 'present'
        } else {
          $ensure = $groups_merge[$groupname]['ensure']
        }
      } else {
        $ensure = 'present'
      }

      if $ensure == 'present' {

        # Set GID and add all (non-local) members to the group
	$groupid      = $allgroupdata[$groupname]['gid']
        $groupmembers = $allgroupdata[$groupname]['members']

        group{ "create_${groupname}":
          name    => "${groupname}",
          ensure  => present,
          gid     => $groupid,
          members => $groupmembers,
        }

      } else {

        group{ "remove_${groupname}":
          name    => "${groupname}",
          ensure  => absent,
        }
      }
    }
  }
}
