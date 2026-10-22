################################################################################
# LVM configuration using a VMWare virtual harddrive attached to a RHEL 9 VM 
#
# This profile prepares a system with second disk to be used as a Puppet-master:
#   - Configure file systems (/data, [/etc|/opt]/puppetlabs, optional /var/log)
#   - Create example configuration files in /data/[examples|nodes]
#   - Create /usr/local/bin/enc.sh
# 
# Before detaching the system from the active Puppet master:
#   - If needed use optional file systems for /var/log|puppetlabs in host yaml:
#       team_linux::profile::prepare_pe_master::lvvarlog: 'lvvarlog' 
#       team_linux::profile::prepare_pe_master::lvvarplabs: 'lvvarplabs' 
#   - Specify different file system sizes if needed in host yaml
#       team_linux::profile::prepare_pe_master::lvoptpup: '30G'
#
# Manual actions after configuring the system via the current master:
#   - Stop and uninstall Puppet agent, empty [/etc|/opt]/puppetlabs directories
#   - Re-mount file systems under [/etc|/opt]/puppetlabs
#   - Download Puppet Enterprise, extract in /data, install 
#   - Configure system
#
################################################################################
class team_linux::profile::prepare_pe_master inherits team_linux::profile::parameters {

  $disk1       = String($facts['vmwc0t0d1']) # custom fact with second VMWare specific virtual SCSI drive 
  $diskdev1    = "/dev/${disk1}" 
  $szdata      = lookup({ name => 'team_linux::profile::prepare_pe_master::lvdata', value_type => String, merge => 'deep', default_value => '5G' })
  $szoptpup    = lookup({ name => 'team_linux::profile::prepare_pe_master::lvoptpup', value_type => String, merge => 'deep', default_value => '10G' })
  $szetcpup    = lookup({ name => 'team_linux::profile::prepare_pe_master::lvetcpup', value_type => String, merge => 'deep', default_value => '5G' })
  $szvarlogpup = lookup({ name => 'team_linux::profile::prepare_pe_master::lvvarlogpup', value_type => String, merge => 'deep', default_value => '5G' })
  $lvvarlog    = lookup({ name => 'team_linux::profile::prepare_pe_master::lvvarlog', value_type => String, merge => 'deep', default_value => 'no_lv_varlog' })
  $lvvarplabs  = lookup({ name => 'team_linux::profile::prepare_pe_master::lvvarplabs', value_type => String, merge => 'deep', default_value => 'no_lv_varplabs' })
  $szvarlog    = lookup({ name => 'team_linux::profile::prepare_pe_master::szvarlog', value_type => String, merge => 'deep', default_value => '5G' })
  $szvarplabs  = lookup({ name => 'team_linux::profile::prepare_pe_master::szvarplabs', value_type => String, merge => 'deep', default_value => '5G' })
  $swapmax     = lookup({ name => 'team_linux::profile::prepare_pe_master::swapmax', value_type => Integer, merge => 'deep', default_value => 15 })
  $dnsdomain   = lookup({ name => 'team_linux::ad_domainname', value_type => String, merge => 'deep', default_value => 'cak-bz.local' })

  $puppetmasterenv = 'productie'
  $vgname          = 'puppetvg'
  $lvdata          = 'lvdata'
  $lvoptpup        = 'optpuppet'
  $lvetcpup        = 'etcpuppet'
  $lvvarlogpup     = 'varlogpuppet'
  $mpdata          = '/data'
  $mpopt           = '/mnt/optpuppetlabs'   # these mountpoints are already 
  $mpetc           = '/mnt/etcpuppetlabs'   #   defined and used by puppetagent
  $mpvarlogpup     = '/var/log/puppetlabs'  # replace and mount manually!
  $mountopt        = 'noatime,nodiratime,discard'
  $filesys         = 'xfs'
  $fqhostname      = "${facts['networking']['hostname']}.${dnsdomain}"
  $encpath         = '/usr/local/bin/enc.sh'

  if ( $facts['disks']["${disk1}"] and $osfamily == 'RedHat' and $rhelmajor >= 9 ) {
    file { [ "${mpdata}", "${mpopt}", "${mpetc}", "${mpvarlogpup}", ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775'
    }

    # Default swap size is 1 Gb
    # swap calculation: add 1 Gb to max $swapmax Gb to system paging
    # Get RAM in bytes, divide by integers ==> integer
    #   (result will be "trimmed down" to integer, so RAM - 1 Gb)
    $ram_size = $facts['memory']['system']['total_bytes']/1024/1024/1024
    #notify{"Calculated RAM in Gb: $ram_size":}
    if $ram_size <= $swapmax {
      if $ram_size <= 1 {
        $swap_size = 1
      } else {
        $swap_size = $ram_size
        #notify{"Swap to add: ${swap_size}":}
      }
    } else {
      $swap_size = $dbswapmax
    }

    class { 'lvm':
      volume_groups => {
        "${vgname}" => {
          createonly => true,
          physical_volumes => [ "${diskdev1}" ],
          logical_volumes  => {
            'lvppswap'    => {
              'ensure'            => 'present',
              'size'              => "${swap_size}G",
              'fs_type'           => 'swap',
            },
            "${lvdata}"   => {
              'ensure'            => 'present',
              'size'              => "${szdata}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mpdata}",
              'mountpath_require' => true,
            },
            "${lvoptpup}" => {
              'ensure'            => 'present',
              'size'              => "${szoptpup}",
              'fs_type'           => "${filesys}",
              # manually replace /opt/puppetlabs
              'mountpath'         => "${mpopt}",
              'mountpath_require' => true,
            },
            "${lvetcpup}" => {
              'ensure'            => 'present',
              'size'              => "${szetcpup}",
              'fs_type'           => "${filesys}",
              # manually replace /opt/puppetlabs
              'mountpath'         => "${mpetc}",
              'mountpath_require' => true,
            },
            "${lvvarlogpup}" => {
              'ensure'            => 'present',
              'size'              => "${szvarlogpup}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mpvarlogpup}",
              'mountpath_require' => true,
            },
          },
        },
      },
    }

    # activate additional swap w/o reboot:
    exec{'activate_lvppswap':
      command => "/sbin/swapon -p 10 /dev/${vgname}/lvppswap",
      timeout  => 0,
      path => [ '/bin', '/usr/bin', '/sbin' ],
      unless => "/sbin/swapon -s | grep $(readlink -f /dev/${vgname}/lvppswap)",
      require => Mount["${mpdata}"],
    }

    if ( "${lvvarlog}" != 'no_lv_varlog' ) {
      logical_volume { "${lvvarlog}":
        ensure       => present,
        volume_group => "${vgname}",
        size         => "${szvarlog}",
        require      => Volume_group["${vgname}"]
        # manually replace /var/log
      }
      filesystem { "/dev/${vgname}/${lvvarlog}":
        ensure         => present,
        fs_type        => "${filesys}",
        mount_options  => "${mountopt}",
        require        => Logical_volume["${lvvarlog}"]
      }
    }

    if ( "${lvvarplabs}" != 'no_lv_varplabs' ) {
      logical_volume { "${lvvarplabs}":
        ensure       => present,
        volume_group => "${vgname}",
        size         => "${szvarplabs}",
        require      => Volume_group["${vgname}"]
        # manually add/replace /var/puppetlabs
      }
      filesystem { "/dev/${vgname}/${lvvarplabs}":
        ensure         => present,
        fs_type        => "${filesys}",
        mount_options  => "${mountopt}",
        require        => Logical_volume["${lvvarplabs}"]
      }
    }

    file { [ "${mpdata}/examples", "${mpdata}/nodes", ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775'
    }

    file { "${mpdata}/examples/pe.conf":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'linuxbeheerscripts/puppetmaster/pe.conf.erb')
    }

    file { "${mpdata}/examples/r10k.yaml":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'linuxbeheerscripts/puppetmaster/r10k.yaml.erb')
    }

    file { "${mpdata}/examples/puppet.conf":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'linuxbeheerscripts/puppetmaster/puppet.conf.erb')
    }

    file { "${encpath}":
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template( 'linuxbeheerscripts/puppetmaster/enc.sh.erb')
    }

    file { "${mpdata}/nodes/${fqhostname}.yaml":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'linuxbeheerscripts/puppetmaster/puppetmaster.yaml.erb')
    }

    file { "${mpdata}/nodes/samplenode.yaml":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'linuxbeheerscripts/puppetmaster/samplenode.yaml.erb')
    }

  } else {
    fail( "This role requires RHEL 9 or later with a VMWare specific second virtual SCSI disk" )
  }

}
