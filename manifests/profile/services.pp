################################################################################
#
# General purpose profile for service states of services not managed elsewhere
#
################################################################################
class team_linux::profile::services {

  # this is a deep lookup
  $services = lookup({ name => "team_linux::services",  merge => 'deep'  })

  keys($services).each | $svc | {

    # the service name is the key, unless the name attribute is specified
    if $services[$svc] == undef or $services[$svc]['name'] == undef {
      $svcname = $svc
    } else {
      $svcname = $services[$svc]['name']
    }

    # if the attribute is undef or present, installed, absent otherwise
    if $services[$svc]  == undef or $services[$svc]['ensure'] == undef or $services[$svc]['ensure'] == 'running' {
      $ensure = running
      $enabled = true

    } else {
      $ensure = stopped
      $enabled = false
    }

    # manage
    service { "$svc":
      name   => $svcname,
      ensure => $ensure,
      enable => $enabled,
    }
  }

}
