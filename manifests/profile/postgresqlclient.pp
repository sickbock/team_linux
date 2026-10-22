################################################################################
# PostgreSQL 12 client on RHEL 8
# workaround missing dnf module support in Puppet 5 + 6 using 'exec' 
################################################################################
class team_linux::profile::postgresqlclient inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    # install the PostgreSQL 12 stream on RHEL 8
    # Still no documented support for dnf:
    # https://tickets.puppetlabs.com/browse/PUP-10235
    exec { 'install_postgresql':
      command  => 'dnf module enable postgresql:12; dnf distro-sync ; dnf -y module install postgresql:12/client',
      provider => 'shell',
      creates  => '/usr/bin/psql',
      onlyif   => "egrep ${mpdata}'[ 	]' /proc/mounts",
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    } 


  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
