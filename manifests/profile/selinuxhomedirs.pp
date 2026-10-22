################################################################################
# Confiure semanage to relabel non-default home directories
#   Required by zabbix_agent.pp & opt_user_homedisk.pp
################################################################################
class team_linux::profile::selinuxhomedirs inherits team_linux::profile::parameters {

  # Check if SELinux is enabled and take measures in case it is
  if $facts['selinux'] == true {
    # Install 'semanage' if missing
    if ( String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) < 8 ) {
      if ! defined(Package['semanageprovider']) {
        #package 'policycoreutils-python':
        package { 'semanageprovider':
          name   => 'policycoreutils-python',
          ensure => present,
        }
      }
    } elsif ( String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) >= 8 ) {
      if ! defined(Package['semanageprovider']) {
        #package 'policycoreutils-python-utils':
        package{ 'semanageprovider':
          name   => 'policycoreutils-python-utils',
          ensure => present,
        }
      }
    } else {
        notice ("\$facts['os']['family'] \$facts['os']['release']['major'] with SELinux enabled = Unmanaged / Unknown Operating System")
    }

    # Configure SELinux for alternative home directories
    exec { 'configure_alternate_home':
      # Following should work for, both, local serviceaccounts and remote directory users
      command => "sed -i 's/usepasswd=False/usepasswd=true/' /etc/selinux/semanage.conf",
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
      require => Package['semanageprovider'],
      unless  => "egrep -i usepasswd=true /etc/selinux/semanage.conf",
    }
  } 

}
