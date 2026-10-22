################################################################################
# Configure Python 3 on RHEL >= 8 (e.g. for AWX)
################################################################################
class team_linux::profile::rhel8python inherits team_linux::profile::parameters {
  #notify{"Running rhel8python":}
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {
    case $facts['os']['release']['major'] {
      '8': {
        $pythonvers = 'python36'
      }
      '9': {
        $pythonvers = 'python39'
      }
      default: {
        $pythonvers = undef
      }
    }

    if defined('$pythonvers') {

      #notify{"This is RHEL >= 8":}
      # just assume package name is sudo
      if ! defined(Package[$pythonvers]) {
        #notify{"Package python36 found":}
        package{ "${pythonvers}":
          ensure => installed,
        }

      # manage python link via alternatives
      exec { 'configure_python3_alternative':
        #command => 'alternatives --set python /usr/bin/python3',
        # Als het niet kan zoals het moet, dan moet het maar zoals het kan:
        command => 'alternatives --remove-all python; alternatives --install /usr/bin/python python /usr/bin/python3 1',
        timeout  => 0,
        #creates => '/etc/alternatives/unversioned-python',
        #unless  => "test -e /usr/bin/python -o -e /etc/alternatives/unversioned-python",
        #subscribe   => File['/usr/bin/python'],
        #refreshonly => true,
        onlyif => 'readlink -f /usr/bin/python|egrep -v python3 3>/dev/null',
        path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        require => Package[$pythonvers],
        }
      }

    }
  } else {
    notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }
}
