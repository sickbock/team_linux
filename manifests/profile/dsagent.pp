class team_linux::profile::dsagent inherits team_linux::profile::parameters {

  #if $facts['roleconfig'] !~ 'team_linux~role~dsrelay' # <- role no longer in use
  if $facts['roleconfig'] !~ 'team_arf~role~arf' and $rhelmajor < 10 { # <- recycle for ARF
    $dsmport   = lookup({ name => 'team_linux::dsmport', default_value => '4120' })
    $dsmurl    = lookup({ name => 'team_linux::dsmurl', default_value => undef })
    $dsaopts   = lookup({ name => 'team_linux::ds_agent_options', default_value => '-U' })
    $lvdata    = lv_dsagent
    $rootname  = split($facts['logical_volumes']['root']['full_name'], '/')
    $vgname    = $rootname[0]
    $mpdata    = '/var/opt/ds_agent'
    $systemmnt = 'var-opt-ds_agent.mount'
    $installdsa     = lookup({ name => 'team_linux::installdsa', merge => 'first', default_value => false }) 
    #notify { "Parameter installdsa is set to: $installdsa" : }
    #notify {"Fact $lvdata: ${facts['logical_volumes'][$lvdata]}" :}
    # Extract the logical volume size safely; if the LV or size doesn't exist, $current_size becomes undef
    $current_lvdata_size = $facts.dig('logical_volumes', $lvdata, 'size')
    #notify {"Fact key lvdata size: ${current_lvdata_size}" :}
    if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' ) {
      $poolid    = '2c9928f989ac97730189d0968b9a10aa'
      $repoid    = 'Trend_Micro_Deep_Security_RHEL8_Signed' 
      #Versions and locking now obsolete
      #$ds_agentv = lookup({ name => 'team_linux::ds_agent_version', default_value => '20.0.0-1337.el8' })
      #$vlockadd  = "dnf versionlock add ds_agent-${ds_agentv}"
      $vlockdel  = 'dnf versionlock delete ds_agent'
      $lockconf  = '/etc/dnf/plugins/versionlock.list' 
      # make sure RHEL 8 required pacakge is installed:
      if ! defined(Package['dnf-command(versionlock)']) {
        package{ 'dnf-command(versionlock)':
          ensure => present,
        }
      }
    } elsif ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '7' ) {
      $poolid    = '2c9928f989ac97730189d0968b9a10aa'
      $repoid    = 'Trend_Micro_Deep_Security_RHEL7_Signed'
      #Versions and locking now obsolete
      #$ds_agentv = lookup({ name => 'team_linux::ds_agent_version', default_value => '20.0.0-1337.el7' })
      #$vlockadd  = "yum versionlock add ds_agent-${ds_agentv}"
      $vlockdel  = "yum versionlock delete ds_agent"
      $lockconf  = '/etc/yum/pluginconf.d/versionlock.list' 
      # make sure RHEL 7 required pacakge is installed:
      if ! defined(Package['yum-plugin-versionlock']) {
        package{ 'yum-plugin-versionlock':
          ensure => present,
        }
      } 
    } elsif ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '9' ) {
#      if ! $facts['logical_volumes']["$lvdata"] {
#        $recreatedsalv = true
#      }
      $poolid    = '2c9928f989ac97730189d0968b9a10aa'
      $repoid    = 'Trend_Micro_Deep_Security_RHEL9_Signed'
      $vlockdel  = "yum versionlock delete ds_agent"
      $lockconf  = '/etc/yum/pluginconf.d/versionlock.list'
    }

    if $installdsa == true {
      #if ( $facts['os']['family'] == 'RedHat' and ( $facts['os']['release']['major'] == '7' or $facts['os']['release']['major'] == '8' or $facts['os']['release']['major'] == '9' ) and $memorysize_mb >= 3600.0 ) {
      if ( $facts['os']['family'] == 'RedHat' and ( $facts['os']['release']['major'] == '7' or $facts['os']['release']['major'] == '8' or $facts['os']['release']['major'] == '9' ) and $facts['memory']['system']['total_bytes'] >= 3774873600 ) {
      # use memorysize_mb >= 3700 (instead of real size 4096) to catch all > 4GiB

        $dsmessage = 'installed'
        $freevgs   = regsubst($facts['volume_groups']['rhel']['free'], /[<>]/, '', 'G')
        #notify { "Free space in VG rhel: $freevgs" : }
        $magnitude = regsubst($freevgs, /([gm]+)/, ',\\1', 'G')
        #notify { "Magnitude VG rhel: $magnitude" : }
        $freenrmg  = split($magnitude, ',')
        #notify { "Free in VG rhel: $freenrmg , G or M" : }
        $freenr    = Numeric ($freenrmg[0])
        #notify { "Free in VG rhel: $freenr" : }
        $freemg    = $freenrmg[1]
        #notify { "Free in VG rhel is G or M: $freemg" : }
        $filesys   = 'xfs'
        $szdata    = lookup({ name => 'team_linux::szdsagentvar', default_value => 2  })
        $dsmanager    = lookup({ name => 'team_linux::dsmanager', default_value => 'clnp32869.cak-bz.local' })

        # debug
        #notify {"Magnitude: ${freemg}, Available: ${freenr}":}
        #notify {"fact: ${facts['ds_agent_registered']}":}
        # $ram_size  = 0 + $facts['memory']['system']['total_bytes']/1024/1024
        # notify {"RAM mb: ${ram_size}" : }

        file { '/etc/motd.d/ds_agent':
          ensure => absent,
        }

#        if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' ) {
#          exec {'add_ds_agent_lock':
#            command     => "${vlockadd}",
#            path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#            unless      => "grep ${$ds_agentv} ${lockconf} >/dev/null 2>&1",
#          }
#        } elsif ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '7' ) {
#          exec {'remove_ds_agent_lock-el7':
#            command     => "${vlockdel}",
#            path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#            unless      => "grep ds_agent-${$ds_agentv} ${lockconf} >/dev/null 2>&1",
#          }
#          exec {'add_ds_agent_lock':
#            command     => "${vlockadd}",
#            path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#            unless      => "grep ${$ds_agentv} ${lockconf} >/dev/null 2>&1",
#          }
#        }

        # Check for sufficient free space to create LV # ??? or if it already exists
        if $freemg == "g" and $freenr > $szdata { 

          # create mountpoint
          file { "${mpdata}":
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0775',
          }

          # LV should already exist already on RHEL 9, if not, most likely we wiped ds_agent .. try recreating it
          exec { "create_${lvdata}":
            command => "lvcreate -L${szdata}G -n ${lvdata} ${vgname}",
            timeout => 0,
            path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            unless  => "lvs /dev/mapper/${vgname}-${lvdata} >/dev/null 2>&1",
            require => [ File["${mpdata}"], ],
          }

          exec { "create_fs_${lvdata}":
            command      => "mkfs.xfs /dev/mapper/${vgname}-${lvdata}",
            timeout      => 0,
            #refreshonly  => true, # uncomment when everything ususally succeeds in one go!
            path         => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            provider     => 'shell',
            unless       => "[[ $(lsblk --fs /dev/mapper/${vgname}-${lvdata} -n --output FSTYPE) == ${filesys} ]]",
            require      => [ File["${mpdata}"], Exec["create_${lvdata}"], ],
          }

          mount { "mount_${mpdata}":
            name    => "${mpdata}",
            device  => "/dev/${vgname}/${lvdata}",
            fstype  => "${filesys}",
            ensure  => mounted,
            require => [ File["${mpdata}"], Exec["create_fs_${lvdata}"], Exec["create_fs_${lvdata}"], ],
          } 

          exec { 'enable_dsrepo':
            command => "subscription-manager attach --pool=${poolid} ; subscription-manager repos --enable ${repoid}",
            unless  => "egrep ${repoid} /etc/yum.repos.d/redhat.repo >/dev/null",
            path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            provider => 'shell',
          }

          # Ensure the ds_agent version is never locked
          exec {'remove_ds_agent_lock':
            command     => "${vlockdel}",
            path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            onlyif      => "grep ds_agent ${lockconf} >/dev/null 2>&1",
          }

          package { 'ds_agent': # package install may fail when enable_dsrepo did not do its job
            name            => 'ds_agent',
            ensure          => installed,
            #ensure          => "${ds_agentv}",
            require         => [ Mount["mount_${mpdata}"], Exec['enable_dsrepo'], ],
            #require         => [ Mount["mount_${mpdata}"], Exec['enable_dsrepo'], Exec['add_ds_agent_lock'], ],
          }

          file{ '/opt/ds_agent/ds_agent_status.sh':
            owner => root,
            group => root,
            mode => '0540',
            require  => [ Package['ds_agent'], Mount["mount_${mpdata}"], Exec['enable_dsrepo'], ],
            content => template('team_linux/ds_agent_status.sh.erb'),
          } ->
          service { 'ds_agent':
            name     => 'ds_agent',
            enable   => true,
            ensure   => 'running', # this stupid thing seems to crash but is required to run for connecting to the master!
            status   => '/opt/ds_agent/ds_agent_status.sh', # this thing seems to love itself, well we won't stop it!
            provider => systemd,
            require  => [ Package['ds_agent'], Mount["mount_${mpdata}"], Exec['enable_dsrepo'], ],
          }

          #if defined('$dsaopts') {
          #  $agent_with_options = shellquote("/opt/ds_agent/dsa_control -a dsm://${dsmanager}:${dsmport}/ ${dsaopts}")
          #}
          if ! $dsmurl {
            $dsmcheck = $dsmanager
          } else {
            $dsmcheck = shellquote("${dsmurl}:${dsmport}")
          }
          exec { 'reset_dsagent':
            command   => '/opt/ds_agent/dsa_control -r',
            path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            unless   => "/opt/ds_agent/sendCommand --get GetConfiguration |egrep -i \"${dsmcheck}|::1:4118|127.0.0.1:4118\" >/dev/null 2>&1", # Give it up when this sadware wants to connect to itself, we tried? didn't we?
            provider => 'shell',
          } ->
          exec { 'register_dsagent':
            command   => "/opt/ds_agent/dsa_control -a dsm://${dsmanager}:${dsmport}/ ${dsaopts}",
            path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            unless   => "/opt/ds_agent/sendCommand --get GetConfiguration |egrep -i \"${dsmcheck}|::1:4118|127.0.0.1:4118\" >/dev/null 2>&1", # Give it up when this sadware wants to connect to itself, we tried? didn't we?
          }
            #command   => "${agent_with_options}",
            #provider => 'shell',

        } elsif String($current_lvdata_size) !~ "${szdata}.*g" {
           if ( $facts['os']['family'] == 'RedHat' and ( $facts['os']['release']['major'] == '8' or $facts['os']['release']['major'] == '9' ) ) {
             notify {"Variable freemg says ${freemg}, Not enough free space in VG ${vgname}, only about ${freenr}${freemg} for ${lvdata} available, at least ${szdata}g required" : }
           } else {
             notify { "Only ${freenr}${freemg} available, at least ${szdata}g required to install DS agent on RHEL 7!" : }
           }
        }

      } else {
          #notify{"${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release or memorysize ${memorysize_mb} is lower than 4096 MiB" : }
          #notify{"Profile dsagent.pp: ${osfamily} is an unsupported operating system family or release ${operatingsystemmajrelease} is unsupported or memorysize ${memorysize_mb} is lower than 4096 MiB":}
        $dsmessage = "Profile dsagent.pp: Deep Security agent not installed because ${osfamily} is an unsupported operating system family or release ${operatingsystemmajrelease} is unsupported or memorysize ${memorysize_mb} is lower than 4096 MiB"
        #Test: # notify { "${dsmessage}" : }
        file { '/etc/motd.d':
          ensure => directory,
        } ->
        file { '/etc/motd.d/ds_agent':
          ensure => file,
          owner => root,
          group => root,
          mode => '0400',
          content => inline_epp($dsmessage),
        }
      }
    } else {
      #notify{"Deep Security agent will not be installed" : }
      exec { 'stop-ds_agent':
        command     => 'systemctl stop ds_agent',
        path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
        refreshonly => true,
      } ->
      package{ 'ds_agent':
        ensure          => absent,
#        install_options => '--nogpgcheck',
      } ~>
      exec {"rm_${mpdata}":
        command     => "rm -rf /${mpdata}/*",
        path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        refreshonly => true,
      } ->
      mount { "umount_${mpdata}":
        name    => "${mpdata}",
        ensure  => absent,
      } ~>
      exec {"wipefs_/dev/${vgname}/${lvdata}":
        command     => "wipefs -a /dev/${vgname}/${lvdata}",
        path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        refreshonly => true,
      }
      # all conditions must be met and LV still needs to exist:
      exec {"lvremove_/dev/${vgname}/${lvdata}":
        command     => "lvremove -y /dev/${vgname}/${lvdata}",
        path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        onlyif      => "lvs /dev/${vgname}/${lvdata} >/dev/null 2>&1",
        require     => [  Exec["rm_${mpdata}"], Mount["umount_${mpdata}"], Exec["wipefs_/dev/${vgname}/${lvdata}"], ],
      } ~>  # make systemd happy and reload, only after previous exec when inactive mount unit exists
      exec {"reload_/dev/${vgname}/${lvdata}":
        command     => "systemctl daemon-reload",
        path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        require     => [  Exec["lvremove_/dev/${vgname}/${lvdata}"], ],
        onlyif      => "systemctl list-units --type mount --all --state=inactive 2>/dev/null |egrep ${mpdata} >/dev/null",
        provider    => 'shell',
        refreshonly => true,
      }
      file { '/etc/motd.d/ds_agent':
        ensure => absent,
      }
      exec {'remove_ds_agent_lock':
        command     => "${vlockdel}",
        path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        onlyif      => "grep ds_agent ${lockconf} >/dev/null 2>&1",
      }
      if "${taintedkernel}X" != "0X" and $facts['team'] != 'team_dba' { # replace after PBI 177190
        $dsa_required_reboot = "DS agent not installed, kernel still tainted, reboot may be required!"
        file { '/etc/motd.d':
          ensure => directory,
        } ->
        file { '/etc/motd.d/ds_agent_removed':
          ensure => file,
          owner => root,
          group => root,
          mode => '0400',
          content => inline_epp($dsa_required_reboot),
        }
      } else {
        file { '/etc/motd.d/ds_agent_removed':
          ensure => absent,
        }
      }
    }
  }
}
