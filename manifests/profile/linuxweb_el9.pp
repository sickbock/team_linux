################################################################################
# Apache web server on RHEL 9
################################################################################
class team_linux::profile::linuxweb_el9 inherits team_linux::profile::parameters {

  
  $usedisk   = lookup({ name => 'team_linux::usedisk', value_type => Boolean, merge => 'first', default_value => true  })
  $httpdrun  = lookup({ name => 'team_linux::httpdrun', value_type => Boolean, merge => 'first', default_value => true  })
  $diskdev   = String($facts['vmwc0t0d1'])
  $vgname    = 'web-vg'
  $lvdata    = 'web-data'
  $filesys   = 'xfs'
  $phpvers   = lookup({ name => 'team_linux::linuxwebphpversion', value_type => String, merge => 'deep', default_value => '8.2'  })
  $szdata    = lookup({ name => 'team_linux::szwebdata', merge => 'unique', default_value => '50G'  })
  $mpdata    = '/var/www'
  # for only 1 disk in the volume group, the following should work
  # LVM module accepts 1 pv as string, more than 1 as array -> should work also
  $pvname    = "lvm_vg_${vgname}_pvs"
  if $vgname in $facts['volume_groups'] {
    $physv = $facts["${pvname}"] # note: will be array when multiple PV's
  } else {
    $physv = "/dev/${diskdev}"
  }

  #notify {"Disk is: ${physv} disk name is: ${diskdev}":}
  
  # $rhelmajor = Integer($facts['os']['release']['major'])
  if ( $facts['os']['family'] == 'RedHat' and $rhelmajor >= 9 and $facts['disks']["$diskdev"] != undef ) {

    #notify {"OS major is: ${facts['os']['release']['major']}":}
    if ! defined(Package[httpd]) {
      if ! $facts['logical_volumes']["$lvdata"] {
        exec{"check_${diskdev}":
          command  => "hdparm -z /dev/${diskdev}",
          timeout  => 0,
          path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        }
      } 
      file { [ "${mpdata}", ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
      } ->
      class { 'lvm':
        volume_groups => {
          "${vgname}" => {
            createonly => true,
            physical_volumes => [ "${physv}" ],
            logical_volumes  => {
              "${lvdata}"   => {
                'ensure'            => 'present',
                'size'              => "${szdata}",
                'fs_type'           => "${filesys}",
                'mountpath'         => "${mpdata}",
                'mountpath_require' => true,
              },
            },
          },
        },
        #notify    => Service['apache'],
      } ->
      package{ 'httpd':
        ensure  => present,
      } ->
      package{ 'mod_ssl':
        ensure  => present,
      }
    } ->
    if ! defined(Package[php]) {
      package { 'phpvers':
        name        => 'php',
        ensure      => "${phpvers}",
        provider    => 'dnfmodule',
        enable_only => true
      } ->
      package{ 'php':
        ensure => present,
      }
    } -> 
    if ! defined(Package[httpd-filesystem]) {
      package{ 'httpd-filesystem':
        ensure => present,
      }
    } -> 
    file { [ "${mpdata}/html", ]:
      ensure => directory,
      owner  => 'apache',
      group  => 'apache',
      mode   => '0755'
    } 

    if $facts['selinux'] {
      exec { 'restorecon_www':
        command => "restorecon -Rv ${mpdata}",
        path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
        require => Mount["${mpdata}"],
        # also return 0 exit when there is no content (yet)
        unless   => "[[ -f /var/www/*/* ]] && matchpathcon -V /var/www/*/* || :",
        provider => 'shell',
      }
    }

    if Boolean($httpdrun) {
      service{ 'apache':
        name    => 'httpd',
        ensure  => 'running',
        enable => 'true',
        require => Package['httpd'],
      }
    } else {
      service{ 'apache':
        name    => 'httdpd',
        require => Package['httpd'],
      }
    }

  } else {
     #fail("OS family $facts['os']['family'] is not 'RedHat', or major release ${rhelmajor} is not >= 9, or $facts['disks'][\"$diskdev\"] doesn't exist")
     #notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release or no extra disk")
      notice ( "Unsupported operating system release or no extra disk" )
  }

}
