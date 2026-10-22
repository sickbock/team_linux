# manages software/update channels

class team_linux::profile::repos inherits team_linux::profile::parameters {

  $java = lookup({ name => 'team_linux::profile::repos::yum_exclude_java', value_type => Boolean, merge => 'deep', default_value => false })
  $dnf_exclude = lookup({ name => 'team_linux::dnf_exclude', value_type => String, merge => 'first', default_value => 'puppet-agent aziot-identity-service' })
  $yum_exclude = lookup({ name => 'team_linux::yum_exclude', value_type => String, merge => 'first', default_value => 'puppet-agent' })

  case $facts['os']['family'] {
    'RedHat' : {
      if $os['name'] != 'CentOS' {

        case true {

          $rhelmajor < 8: {

            # manage /etc/yum.conf
            file{ '/etc/yum.conf':
              ensure  => file,
              owner   => root,
              group   => root,
              mode    => '0644',
              content => template('team_linux/yum.conf.erb')
            }

            # the template disables the rhnplugin - we don't do rhn but use
            # satellite instead
            file{ '/etc/yum/pluginconf.d/rhnplugin.conf':
              ensure  => file,
              owner   => root,
              group   => root,
              mode    => '0644',
              content => template('team_linux/rhnplugin.conf.erb')
            }
          }

          $rhelmajor >= 8: {
            # manage /etc/dnf/dnf.conf
            file{ '/etc/dnf/dnf.conf':
              ensure  => file,
              owner   => root,
              group   => root,
              mode    => '0644',
              content => template('team_linux/dnf.conf.erb')
            }
            # remove/correct left-overs from previous Puppetcode
            file{ '/etc/yum.conf':
              ensure  => link,
              target  => '/etc/dnf/dnf.conf',
            }
            file{ '/etc/yum/pluginconf.d/rhnplugin.conf':
              ensure  => absent,
            }
          }

        default: {
          fail( "Unhandled OS major release ${osfamily} ${rhelmajor} in team_linux::profile::repos" )
        }
      }
      } elsif $os['name'] != 'CentOS' {
        # manage /etc/yum.conf
        file{ '/etc/yum.conf':
          ensure  => file,
          owner   => root,
          group   => root,
          mode    => '0644',
          content => template('team_linux/centosyum.conf.erb')
        }
        # manage /etc/yum.repos.d/CentOS-Base.repo
        file{ '/etc/yum.repos.d/CentOS-Base.repo':
          ensure  => file,
          owner   => root,
          group   => root,
          mode    => '0644',
          content => template('team_linux/CentOS-Base.repo.erb')
        }
        file{ '/etc/yum/pluginconf.d/rhnplugin.conf':
          ensure  => absent,
        }
      }
    }
    default: {
      fail( "unhandled osfamily ${osfamily} in team_linux::profile::repos" )
    }
  }
}
