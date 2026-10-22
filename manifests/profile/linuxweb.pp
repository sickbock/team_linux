################################################################################
# Apache web server on RHEL 8
#   use undocumented PE dnf module support - hopefully it keeps working :-(
################################################################################
class team_linux::profile::linuxweb inherits team_linux::profile::parameters {
 
  $diskdev   = "/dev/${appdisk}"
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' and  $facts['disks']["$appdisk"] != undef ) {

    $vgname    = 'web-vg'
    $lvdata    = 'web-data'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::szwebdata', merge => 'unique', default_value => '20G'  })
    $httpdvers = lookup({ name => 'team_linux::linuxwebhttpdversion', value_type => String, merge => 'deep', default_value => '2.4'  })
    $phpvers   = lookup({ name => 'team_linux::linuxwebphpversion', value_type => String, merge => 'deep', default_value => '7.2'  })
    $mpdata    = '/var/www'

    if ! defined(Package[httpd]) {
      if ! $facts['logical_volumes']["$lvdata"] {
        exec{"check_${diskdev}":
          command  => "hdparm -z ${diskdev}",
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
            physical_volumes => [ "${diskdev}" ],
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
        notify    => Service['apache'],
      } ->
      package { 'httpdvers':
        name        => 'httpd',
        ensure      => "${httpdvers}",
        provider    => 'dnfmodule',
        enable_only => true
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

    service{ 'apache':
      name    => 'httpd',
      ensure  => running,
      enable => 'true',
      require => Package['httpd'],
    }

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release or no extra disk")
  }

}
