class team_linux::profile::gitlab inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    $diskdev   = "/dev/${appdisk}"
    $vgname    = 'gitlabvg'
    $lvdata    = 'gitlabvar'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::szgitlabvar', default_value => '12G'  })
    $mpdata    = '/var/opt/gitlab'


    exec{"check_${diskdev}":
      command => "hdparm ${diskdev}",
      timeout  => 0,
      unless => "grep ready /var/lib/provisioning/state",
      path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    }


    # create mountpoint
    file { [ "${mpdata}", ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775'
    }

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
      require => [ Exec["check_${diskdev}"],
                   File["${mpdata}"], ],
    } 

    if ! defined(Package[curl]) {
      package{ 'perl':
        ensure => present,
      }
    }
    if ! defined(Package[policycoreutils]) {
      package{ 'perl':
        ensure => present,
      }
    }
    if ! defined(Package[policycoreutils-python-utils]) {
      package{ 'perl':
        ensure => present,
      }
    }
    if ! defined(Package[perl]) {
      package{ 'perl':
        ensure => present,
      }
    }

    file { '/etc/yum.repos.d/gitlab.repo':
      content => template( 'team_linux/gitlab.repo.rb' ),
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
    } ->
    cron { 'update_gitlabce':
      command => '[[ $(dnf check-update gitlab-ce >/dev/null 2>&1; echo $?) -eq 100 ]] && { /usr/bin/dnf -y update gitlab-ce >/var/log/gitlab-update.txt 2>&1 && { tail /var/log/gitlab-update.txt | /usr/bin/mailx -s "GitLab $(egrep -A1 Upgraded:  /var/log/gitlab-update.txt)" -a /var/log/gitlab-update.txt linuxbeheer@hetcak.nl jpoutre@hetcak.nl roostendorp@hetcak.nl secops@hetcak.nl ; } || tail /var/log/gitlab-update.txt | /usr/bin/mailx -s "GitLab upgrade FAILED!" -a /var/log/gitlab-update.txt linuxbeheer@hetcak.nl jpoutre@hetcak.nl roostendorp@hetcak.nl secops@hetcak.nl; }',
      user    => 'root',
      minute  => 33,
      hour    => 3,
    }



#    service { 'servicename':
#      name     => 'servicename',
#      enable   => true,
#      provider => systemd,
#    }


  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
