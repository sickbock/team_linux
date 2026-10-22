################################################################################
# Add disk for file system mounted at /opt/<username>
# To be used by applications that run from an application home directory in /opt
#
# Depends on selinuxhomedirs.pp
#
# Note: this profile should, most of the time, be used with a local
# serviceaccount, when using this with a remote account, your mileage may vary
# at least make sure the user has a home directory defined equal to the 
# mountpoint used in Hiera ('team_linux::opt_user_mountp' or /opt/$app_owner)
################################################################################
class team_linux::profile::opt_user_homedisk inherits team_linux::profile::parameters {

  $homedisk    = lookup({ name => 'team_linux::opt_user_homedisk', merge => 'first', default_value => undef })
  if $homedisk != undef {
    $diskdev   = "/dev/${homedisk}"
    $vgname    = 'applicationhome-vg'
    $lvdata    = 'applicationhome-lv'
    $filesys   = 'xfs'
    $app_owner = lookup({ name => 'team_linux::opt_application_user', default_value => undef })
    if defined('$app_owner') {
      $homedir   = lookup({ name => "team_linux::accountdata.${app_owner}.homedir", default_value => undef })
    } 
    $app_group = lookup({ name => 'team_linux::opt_application_group', default_value => undef })
    $dirmode   = lookup({ name => 'team_linux::opt_user_mode', value_type => String, merge => 'first', default_value => '750'  })
    $szdata    = lookup({ name => 'team_linux::opt_user_homesz', value_type => String, merge => 'first', default_value => '49G'  })
    $mpdata    = lookup({ name => 'team_linux::opt_user_mountp', default_value => undef  })

    # By default, application -, user - and mountpoint name are all the same:
    if ! $mpdata {
      $mpdata  = "/opt/$app_owner"
    }

    if ! $app_owner or ! $app_group {
      fail("No user or group defined for mountpoint /opt/<applicaitonhome>")
    }

    file { [ "${mpdata}", ]:
      ensure => directory,
      owner  => "$app_owner",
      group  => "$app_group",
      mode   => "$dirmode",
    }

#    class { 'lvm':
#      lvm::volume_groups => {
#        "${vgname}" => {
#          createonly => true,
#          physical_volumes => [ "${diskdev}" ],
#          logical_volumes  => {
#            "${lvdata}"   => {
#              'ensure'            => 'present',
#              'size'              => "${szdata}",
#              'fs_type'           => "${filesys}",
#              'mountpath'         => "${mpdata}",
#              'mountpath_require' => true,
#            },
#          },
#        },
#      },
#    }

    lvm::volume { "${lvdata}":
      ensure            => present,
      pv                => "${diskdev}",
      vg                => "${vgname}",
      fstype            => "${filesys}",
      size              => "${szdata}",
    } # Now add normal mount (i.e. not proviced via lvm module):
    -> mount{ "${mpdata}":
      name    => "${mpdata}",
      fstype  => "${filesys}",
      device  => "/dev/${vgname}/${lvdata}",
      ensure  => mounted,
      require => [ File["${mpdata}"], ]
    }

    exec{'app_mp_owner':
      command => "chown ${app_owner}:${app_group} ${mpdata}",
      timeout  => 0,
      # mountpoint owner can only be changed during second Puppet run, so do it now or expect failures
      onlyif => "grep -v '^ready$' /var/lib/provisioning/state",
      path => [ '/bin', '/usr/bin', '/sbin' ],
      require => Mount["${mpdata}"],
    }
    # Maybe the following should be removed from here (overlaps with selinuxhomedir)
    # Test: # notify {"Value of homedir: ${homedir}" : }
    if ( $facts['selinux'] and "X${homedir}" !~ "X" ) {
      # Moved selinux configuration part to selinuxhomedirs.pp (wher package 'semanageprovider' is defined)
      exec { 'configure_alternate_home_opt':
        # Following should work for, both, local serviceaccounts and remote directory users
        # Just hope and pray selinuxhomedirs.pp installed the software ...
        # The following is not yet tested ... 
        command => "semanage fcontext -m -t user_home_dir_t ${mpdata}",
        path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
        require => [
                     Mount["${mpdata}"],
                     Exec['app_mp_owner'],
                   ],
        unless  => "/bin/ls -dZ ${mpdata} | /bin/egrep '^user_home_dir_t'",
      }
    }
  } 
}
