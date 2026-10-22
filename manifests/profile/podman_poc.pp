class team_linux::profile::podman_poc inherits team_linux::profile::parameters {
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '9' ) {

    if ! defined(Package[git]) {
      package { 'Install git for container tools':
        name        => 'git',
        ensure      => present,
      }
    }
    if ! defined(Package[container-tool]) {
      package { 'Install container tools':
        name        => 'container-tools',
        ensure      => present,
      }
    } ->
    if ! defined(Package[podman-docker]) {
      package { 'Install podman-docker for container tools':
        name        => 'podman-docker',
        ensure      => present,
      }
    } ->
    service {'enable_podman_socket':
      name   => 'podman.socket',
      ensure => running,
      enable => true,
    } -> 
    file {'/usr/local/bin/install_docker_compose':
      owner   => 'root',
      group   => 'root',
      mode    => '0550',
      content => template('team_linux/install_docker_compose.sh.erb'),
    } ~>
    exec {'install_docker_compose':
      command     => '/usr/local/bin/install_docker_compose', 
      refreshonly => true,
      path        => [ '/bin', '/usr/bin', '/sbin', '/usr/local/bin' ],
      creates     => '/usr/local/bin/docker-compose',
      provider    => 'shell',
    }      
  }
}
