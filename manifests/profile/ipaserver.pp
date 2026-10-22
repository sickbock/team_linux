################################################################################
# Install Red Hat IdM on RHEL 8
# workaround missing dnf module support in Puppet 5 using 'exec' 
#   note: workaroune and tests are not optimal & require multiple Puppet runs
################################################################################
class team_linux::profile::ipaserver inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    exec { 'install_ipaserver':
      command  => 'dnf module enable idm:DL1; dnf distro-sync ; dnf -y module install idm:DL1/{dns,adtrust}',
      provider => 'shell',
      creates  => '/usr/sbin/ipa-server-install',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    } -> # Make Jan Marten happy
    file {'/var/lib/provisioning':
      ensure => directory,
    } ->
    file {'/var/lib/provisioning/state':
      content => 'ready',
    }
#    exec{ 'p_ready':
#      command     => 'echo "ready" > /var/lib/provisioning/state',
#      path        => [ '/bin', '/usr/bin', '/sbin' ],
#      unless      => 'grep ready /var/lib/provisioning/state',
#    }

    # Place IPA/IdM related scripting in secure directory
    file { [ "/root/ipascripts", ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700'
    }
    file { '/root/ipascripts/ad2ipagroups.sh':
      content => template( 'team_linux/ad2ipagroups.sh.erb' ),
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0700'
    }

    file { '/root/ipascripts/sudocmdgroup.sh':
      content => template( 'team_linux/sudocmdgroup.sh.erb' ),
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0700'
    }

    # Remove unnecessary packages with not running services
    service { 'rtkit-daemon.service':
      ensure => 'stopped',
      enable => 'false',
    }
    if ! defined(Package['pipewire']) {
      package{ 'pipewire':
        ensure => absent,
      }
    } ->
    if ! defined(Package['rtkit']) {
      package{ 'rtkit':
        ensure => absent,
      }
    }
  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
