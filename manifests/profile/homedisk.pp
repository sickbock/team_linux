################################################################################
# Add disk for /home
################################################################################
class team_linux::profile::homedisk inherits team_linux::profile::parameters {

  $homedisk  = lookup({ name => 'team_linux::homedisk', merge => 'first', default_value => '/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:1:0' })

  exec { 'homedisk-present':
    command => '/bin/true',
    onlyif  => "test -h ${homedisk}",
    path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
  }

  if $homedisk != undef {
    $diskdev   = "${homedisk}"
    $vgname    = 'home-vg'
    $lvhome    = 'home'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::szhome', value_type => String, merge => 'first', default_value => '49G'  })
    $mphome    = '/home'

    if ! $facts['logical_volumes']["$lvhome"] {
      exec{"check_${diskdev}":
        command => "hdparm ${diskdev}",
        timeout  => 0,
        path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      }
    } 
    file { [ "${mphome}", ]:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0775',
      require => Exec['homedisk-present'],
    }

#    class { 'lvm':
#      volume_groups => {
#        "${vgname}" => {
#          createonly => true,
#          physical_volumes => [ "${diskdev}" ],
#          logical_volumes  => {
#            "${lvhome}"   => {
#              'ensure'            => 'present',
#              'size'              => "${szdata}",
#              'fs_type'           => "${filesys}",
#              'mountpath'         => "${mphome}",
#              'mountpath_require' => true,
#            },
#          }
#        },
#      },
#    }

    lvm::volume { "${lvhome}":
      ensure            => present,
      pv                => "${diskdev}",
      vg                => "${vgname}",
      fstype            => "${filesys}",
      size              => "${szdata}",
      require => [ Exec['homedisk-present'], File["${mphome}"], ],
    } ->
    # Now add normal mount (i.e. not proviced via lvm module):
    mount{ "${mphome}":
      name => "${mphome}",
      device => "/dev/${vgname}/${lvhome}",
      ensure => mounted,
      require => Exec['homedisk-present'],
    }

  } else {
    fail( "No disk for home found")
  }
}
