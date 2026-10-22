################################################################################
#
# ensure packages being either installed or absent
# note that we avoid the use of 'latest' as that would
# update packages when a puppet run finds a a new one available.
#
#
################################################################################
class team_linux::profile::packages inherits team_linux::profile::parameters {

  # this is a deep lookup
  $allpackages = lookup({ name => "team_linux::packages",  merge => 'deep'  })
  $packages    = $allpackages - ['smartmontools','policycoreutils','policycoreutils-python-utils']

  keys($packages).each | $pkg | {

    # the package name is the key, unless the name attribute is specified
    if $packages[$pkg] == undef or $packages[$pkg]['name'] == undef {
      $pkgname = $pkg
    } else {
      $pkgname = $packages[$pkg]['name']
    }

    # if the attribute is undef or present, installed, absent otherwise
    if $packages[$pkg] == undef or $packages[$pkg]['ensure'] == undef or $packages[$pkg]['ensure'] == 'present' {
      $ensure = installed
    } else {
      $ensure = absent
    }

    # get install options
    if $packages[$pkg] == undef or $packages[$pkg]['install_options'] == undef {
      $install_options = undef
    } else {
      $install_options = $packages[$pkg]['install_options']
    }

    # get uninstall options
    if $packages[$pkg] == undef or $packages[$pkg]['uninstall_options'] == undef {
      $uninstall_options = undef
    } else {
      $uninstall_options = $packages[$pkg]['uninstall_options']
    }

    # check if any repos need to be enabled
    if $ensure != installed or $packages[$pkg] == undef or $packages[$pkg]['repository'] == undef {
      $repository = undef
    } else {
      if $facts['repositories'] != undef and $facts['repositories'][$packages[$pkg]['repository']] != undef {
        $repository = $packages[$pkg]['repository']
      } else {
        $repository = undef
      }
    }

    #notify{ "${pkg} repository=$repository": }
    #notify{ "${pkg} repository_facts=${facts['repositories'][$repository]}": }

    if $facts['os']['family'] == 'Suse' or $repository == undef or $facts['repositories'][$repository] == 'enabled' {
      exec{ "${pkg}_repoenable":
        command => "/bin/true",
        onlyif  => "/bin/false",
        path    => ['/usr/bin', '/bin',],
      }
    } else {
      exec{ "${pkg}_repoenable":
        command => "subscription-manager repos --enable ${repository}",
        path    => ['/usr/sbin', '/sbin',],
      }
    }

    # manage
    if ! defined(Package[$pkg]) {
      package { "$pkg":
        name              => $pkgname,
        ensure            => $ensure,
        install_options   => $uninstall_options,
        uninstall_options => $uninstall_options,
        require           => [ Exec["${pkg}_repoenable"], ],
      }
    }
  }

}
