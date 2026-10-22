################################################################################
# Add disk for additional paging required by applications other than oracle
#
################################################################################
class team_linux::profile::addapplicationswap inherits team_linux::profile::parameters {

  $appswapdisk = lookup({ name => 'team_linux::appswappdisk', merge => 'first', default_value => undef })
  $appswapsz = lookup({ name => 'team_linux::appswapsz', merge => 'first', default_value => undef })
  if $appswapdisk != undef {
    $diskdev      = "/dev/${appswapdisk}"
    $vgname       = 'appswap-vg'
    $lvdata       = 'appswap-lv'
    $appswapmax   = lookup({ name => 'team_linux::appswapmax', value_type => Integer, merge => 'deep', default_value => 15 })

    # Default swap size is 1 Gb
    # swap calculation: add 1 Gb to max $dbswapmax Gb to system paging
    # Get RAM in bytes, divide by integers ==> integer 
    #   (result will be "trimmed down" to integer, so RAM - 1 Gb)
    $ram_size = 0 + $facts['memory']['system']['total_bytes']/1024/1024/1024
    ##notify{"Calculated RAM in Gb: $ram_size":}
    if $appswapsz != undef {
      $swap_size = $appswapsz
    } else {
      case true {
        $ram_size <= 1: { $swap_size = 1 }
        $ram_size <= $appswapmax: { $swap_size = $ram_size }
        default: { $swap_size = $appswapmax }
      }
    }

#    class { 'lvm':
#      lvm::volume_groups => {
#        "${vgname}" => {
#          createonly => true,
#          physical_volumes => [ "${diskdev}" ],
#          logical_volumes  => {
#            "${lvdata}"   => {
#              'ensure'            => 'present',
#              'size'              => "${swap_size}G",
#              'fs_type'           => swap,
#            },
#          },
#        },
#      },
#    }

#    lvm::volume_group => { "${vgname}":
#      'ensure'           => present,
#      'physical_volumes' => [ "${diskdev}" ],
#    }
#    lvm::volume { "${lvdata}":
#      'ensure'  => present,
#      'fs_type' => swap,
#      'size'    => "${swap_size}G",
#    }
    lvm::volume { "${lvdata}":
      ensure  => present,
      pv      => "${diskdev}",
      vg      => "${vgname}",
      fstype  => swap,
      size    => "${swap_size}G",
    }
  }
}
