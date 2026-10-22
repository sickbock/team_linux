################################################################################
#
# This profile prepares a system with second disk to be used as a Puppet-master:
#   - Configure file systems (/data, [/etc|/opt]/puppetlabs, optional /var/log)
#   - Create example configuration files in /data/[examples|nodes]
#   - Create /usr/local/bin/enc.sh
# 
# Before detaching the system from the active Puppet master:
#   - If needed use optional file systems for /var/log|puppetlabs in host yaml:
#       team_linux::profile::prepare_ce_master::lvvarlog: 'lvvarlog' 
#       team_linux::profile::prepare_ce_master::lvvarplabs: 'lvvarplabs' 
#   - Specify different file system sizes if needed in host yaml
#       team_linux::profile::prepare_ce_master::lvoptpup: '30G'
#
# Manual actions after configuring the system via the current master:
#   - Stop and uninstall Puppet agent, empty [/etc|/opt]/puppetlabs directories
#   - Re-mount file systems under [/etc|/opt]/puppetlabs
#   - Download Puppet Enterprise, extract in /data, install 
#   - Configure system
#
################################################################################
class team_linux::profile::prepare_ce_master inherits team_linux::profile::parameters {

  $diskname   = lookup({ name => 'team_linux::profile::prepare_ce_master::diskname', value_type => String, merge => 'deep', default_value => '/dev/sdb' })
  $szdata     = lookup({ name => 'team_linux::profile::prepare_ce_master::lvdata', value_type => String, merge => 'deep', default_value => '5G' })
  $szoptpup   = lookup({ name => 'team_linux::profile::prepare_ce_master::lvoptpup', value_type => String, merge => 'deep', default_value => '10G' })
  $szetcpup   = lookup({ name => 'team_linux::profile::prepare_ce_master::lvetcpup', value_type => String, merge => 'deep', default_value => '5G' })
  $lvvarlog   = lookup({ name => 'team_linux::profile::prepare_ce_master::lvvarlog', value_type => String, merge => 'deep', default_value => 'no_lv_varlog' })
  $lvvarplabs = lookup({ name => 'team_linux::profile::prepare_ce_master::lvvarplabs', value_type => String, merge => 'deep', default_value => 'no_lv_varplabs' })
  $szvarlog   = lookup({ name => 'team_linux::profile::prepare_ce_master::szvarlog', value_type => String, merge => 'deep', default_value => '5G' })
  $szvarplabs = lookup({ name => 'team_linux::profile::prepare_ce_master::szvarplabs', value_type => String, merge => 'deep', default_value => '5G' })
  $szpgsql    = lookup({ name => 'team_linux::profile::prepare_ce_master::szpgsql', value_type => String, merge => 'deep', default_value => '20G' })
  $szpgsqlbck = lookup({ name => 'team_linux::profile::prepare_ce_master::szpgsqlbck', value_type => String, merge => 'deep', default_value => '20G' })
  $swapmax    = lookup({ name => 'team_linux::profile::prepare_ce_master::swapmax', value_type => Integer, merge => 'deep', default_value => 15 })
  $dnsdomain  = lookup({ name => 'team_linux::ad_domainname', value_type => String, merge => 'deep', default_value => 'cak-bz.local' })

  $puppetmasterenv = 'productie'
  $vgname          = 'puppetvg'
  $lvdata          = 'lvdata'
  $lvoptpup        = 'optpuppet'
  $lvetcpup        = 'etcpuppet'
  $mpdata          = '/data'
  $mpopt           = '/mnt/optpuppetlabs'  # these mountpoints are already 
  $mpetc           = '/mnt/etcpuppetlabs'  #   defined and used by puppetagent
  #$mpvar          = '/var/log'            # replace and mount manually!
  $mountopt        = 'noatime,nodiratime,discard'
  $filesys         = 'xfs'
  $fqhostname      = "${facts['networking']['hostname']}.${dnsdomain}"
  $encpath         = '/usr/local/bin/enc.sh'

  file { [ "${mpdata}", "${mpopt}", "${mpetc}", ]:
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

  # create mountpoint
  file { [ '/var/lib/pgsql', '/var/lib/pgsql_backup', ]:
    ensure => directory,
  } ->
  class { 'lvm':
    volume_groups => {
      "${vgname}" => {
        createonly => true,
        physical_volumes => [ "${diskname}" ],
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
          'pgsql-data' => {
            'ensure'             => 'present',
            'size'               => "${szpgsql}",
            'fs_type'            => "${filesys}",
            'mountpath'          => '/var/lib/pgsql',
            'mountpath_require'  => true,
          },
          'pgsql-backup' => {
            'ensure'            => 'present',
            'size'              => "${szpgsqlbck}",
            'fs_type'           => "${filesys}",
            'mountpath'         => '/var/lib/pgsql_backup',
            'mountpath_require' => true,
          },
        },
      },
    },
  }

  # activate additional swap w/o reboot:
  exec{"activate_${lvdbswap}":
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

}
