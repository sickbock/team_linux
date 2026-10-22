class team_linux::profile::systemmounts {

#  # it's impossible to make this profile work on all the diversity we have.
#  # but it is too usefull and works on newer, standard nodes so we sanity check the hostname,
#  # it must be cln[otap](\d){5} or else we fail.
#  # do NOT include this profile in roles applied to nodes that existed before

  $tmpmanaged = lookup({ name => 'team_dba::tmpmanaged', default_value => 'yes' })

#  if $facts['networking']['hostname'] =~ /cln[otap][[:digit:]]{5}/ {

    $mounts = lookup({ name => "team_linux::systemmounts",  merge => 'deep'  })

    keys($mounts).each | $dev | {

      $mounts_dev = $mounts["${dev}"]

      $mountpoint = $mounts_dev['mountpoint']
      $fstype = $mounts_dev['fstype']
      $fsoptions = $mounts_dev['fsoptions']


      if $facts['mountpoints'][$mountpoint] != undef and
        $mountpoint != undef and
        $fstype     != undef and
        $fsoptions  != undef {

        # we need to move to /dev/mapper/vgname-lvname over /dev/vgname/lvname
        # as puppet and /proc/mounts use the mapper variant always
        # to properly define and recognize we need to adhere to the same standard
        # puppet will enforce it for you below

        if $dev =~ /^\/dev\/system\/.*/ {
          case $dev {
            '/dev/system/root': { $mapper_dev = "/dev/mapper/system-root" }
            '/dev/system/home': { $mapper_dev = "/dev/mapper/system-home" }
            '/dev/system/tmp': { $mapper_dev = "/dev/mapper/system-tmp" }
            '/dev/system/var': { $mapper_dev = "/dev/mapper/system-var" }
            '/dev/system/varlog': { $mapper_dev = "/dev/mapper/system-varlog" }
            '/dev/system/varlogaudit': { $mapper_dev = "/dev/mapper/system-varlogaudit" }
            '/dev/system/varlogaudit': { $mapper_dev = "/dev/mapper/system-varlogaudit" }
            default: { fail( "unrecognized ${dev} in systemmounts.pp" ) }
          }
        } else {
          $mapper_dev = $dev
        }

        # extra checks before apply; the
        # - device
        # - filsystemtype
        # - mountpoint
        # MUST match before we apply otherwise we
        # might alter fstab such that boots will fail

        if $facts['mountpoints'][$mountpoint]['device'] == $mapper_dev and
            $facts['mountpoints'][$mountpoint]['filesystem'] == $fstype {

          if $mountpoint == '/' {
            $fscheckpass = 1
          } else {
            $fscheckpass = 2
          }

          case $mountpoint {
            '/tmp': {
              $managemp = $tmpmanaged
            }
            '/tmp': {
              $managemp = 'yes'
            }
          }

          if $managemp == 'yes' {
            mount{ "root_${dev}":
              name => "${mounts_dev['mountpoint']}",
              ensure   => "mounted",
              atboot   => true,
              device   => "${mapper_dev}",
              fstype   => "${fstype}",
              options  => "${fsoptions}",
              remounts => true,
              pass     => $fscheckpass,
            }
          }
        }
      }
    }
#  }
}
