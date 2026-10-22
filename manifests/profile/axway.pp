################################################################################
# Prepare RHEL 8 system voor Axway Automor installation
################################################################################
class team_linux::profile::axway inherits team_linux::profile::parameters {
 
  #$mpdata    = '/opt/axway'
  if $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' {

    $diskdev      = "/dev/${appdisk}"
    $vgname       = 'axway-vg'
    $lvdata       = 'axway-data'
    $filesys      = 'xfs'
    $mpowner      = 'automator'
    $mpgroup      = 'automator'
    $mpmode       = '0750'
    $szdata       = lookup({ name => 'team_linux::szaxwaydata', merge => 'unique', default_value => '20G'  })
    $mpdata       = lookup({ name => 'team_linux::axwaymp', default_value => "/opt/${mpowner}" })
    $satellite    = lookup({name => 'team_linux::satellite_server', default_value => 'satellite.cak-bz.local' })
    $axwaywar     = 'automator-webui.war'
    $axwayenv     = "export AXWAY_AUTOMATOR_NEW_UI_HOME=/opt/automator/webui\n"
    $catalinahome = '/opt/rh/jws5/root/usr/share/tomcat'
    $jws5poolid   = '2c9928f98d0dd65a018da768ca1c1620'
    $jws5repo     = 'jws-5-for-rhel-8-x86_64-rpms'
    $jws5tomcat   = 'jws5-tomcat'
    $jws5gid      = 'jws5'
    $jws5gname    = 'JBoss Web Server'
    $rserverstate = lookup({name => 'team_linux::rserverstate', default_value => 'running' })


    if ! $facts['logical_volumes']["$lvdata"] {
      exec{"check_${diskdev}":
        command => "hdparm ${diskdev}",
        timeout  => 0,
        path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      }
    } 

    # create mountpoint
    file { [ "${mpdata}", ]:
      ensure => directory,
      owner  => $mpowner,
      group  => $mpgroup,
      mode   => $mpmode
    } ->

    class { 'lvm':
      volume_groups => {
        "${vgname}" => {
          createonly => true,
          physical_volumes => [ "${diskdev}", ],
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
      require => [ File["${mpdata}"], ],
    } 

    if !defined(Package['libffi']) {
      package{ 'libffi':
        ensure => installed,
      }
    } ->
    file{ '/usr/lib64/libffi.so.5':
      ensure  => link,
      target  => '/usr/lib64/libffi.so.6',
    } ->
    file{ '/usr/lib64/libffi.so.5.0.1':
      ensure  => link,
      target  => '/usr/lib64/libffi.so.6.0.2',
    } ->
    file { '/etc/init.d/pserver':
      owner   => 'root',
      group   => 'root',
      mode    => '0550',
      content => template('team_linux/pserver.erb'),
      require => Mount["${mpdata}"],
    } ~>
    service{ 'axwaypserver':
      name      => 'pserver',
      ensure    => running,
      enable    => true,
      provider  => 'redhat',
      require   => [ Mount["${mpdata}"], ],
      subscribe => File['/etc/init.d/pserver'],
    }
    file { '/etc/init.d/mserver':
      owner   => 'root',
      group   => 'root',
      mode    => '0550',
      content => template('team_linux/mserver.erb'),
      require => Mount["${mpdata}"],
    } ~>
    service{ 'axwaymserver':
      name      => 'mserver',
      ensure    => running,
      enable    => true,
      provider  => 'redhat',
      require   => [ Mount["${mpdata}"], ],
      subscribe => File['/etc/init.d/mserver'],
    }
    file { '/etc/init.d/rserver':
      owner   => 'root',
      group   => 'root',
      mode    => '0550',
      content => template('team_linux/rserver.erb'),
      require => Mount["${mpdata}"],
    } #~>
    if $rserverstate == 'running' {
    service{ 'axwayrserver':
      name      => 'rserver',
      ensure    => $rserverstate,
      enable    => true,
      provider  => 'redhat',
      require   => [ Mount["${mpdata}"], ],
      subscribe => File['/etc/init.d/rserver'],
    }
    }

    if !defined(Package['java-1.8.0-openjdk']) {
      package{ 'java-1.8.0-openjdk':
        ensure => installed,
      }
    } ->
    if !defined(Package['java-1.8.0-openjdk-devel']) {
      package{ 'java-1.8.0-openjdk-devel':
        ensure => installed,
      }
    } ->
    if !defined(Package['openssl']) {
      package{ 'openssl':
        ensure => installed,
      }
    } ->
    if !defined(Package['apr']) {
      package{ 'apr':
        ensure => installed,
      }
    } #->
#    if !defined(Package["${jws5tomcat}"]) {
#      exec { 'enable_jws5repo':
#        command => "subscription-manager attach --pool=${jws5poolid} ; subscription-manager repos --enable ${jws5repo}",
#        unless  => "dnf repolist --enabled ${jws5repo} |egrep -i ${jws5repo}",
#        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#        provider => 'shell',
#      } ~>
#      exec{'groupinstall_jws5':
#        command => "dnf groupinstall -y ${jws5gid}",
#        timeout  => 0,
#        provider => 'shell',
#        unless => "rpm -q ${jws5tomcat}",
#        path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#        creates => "${catalinahome}",
#      } ->
#      exec{'download_axway_war_file':
#        command => "curl -k -o ${catalinahome}/webapps/${axwaywar} https://${satellite}/pub/axway/${axwaywar}",
#        timeout  => 0,
#        provider => 'shell',
#        unless => "unzip -v ${catalinahome}/webapps/${axwaywar} >/dev/null 2>&1",
#        path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#        creates => "${catalinahome}webapps/${axwaywar}",
#      } ->
#      file { "${catalinahome}/automator":
#        ensure => directory,
#        owner => tomcat,
#        group => tomcat,
#        mode => '0770',
#        require => [ Exec['groupinstall_jws5'], Exec['download_axway_war_file'], ],
#      } ->
#      file { "${catalinahome}/bin/setenv.sh":
#        ensure => file,
#        owner => tomcat,
#        group => tomcat,
#        mode => '0550',
#        notify => Service['jws5-tomcat'],
#        content => inline_epp($axwayenv),
#        require => [ Exec['groupinstall_jws5'], Exec['download_axway_war_file'], ],
#      }
#    } ~> 
#    service{ 'jws5-tomcat':
#      enable    => true,
#    } 

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
