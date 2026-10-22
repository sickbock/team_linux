class team_linux::profile::httpproxyserver inherits team_linux::profile::parameters {
  # if boolean $usehttpproxyserver and $httpproxyserver defined, configure proxy
  if $usehttpproxyserver and defined('$httpproxyserver') {
    file { '/etc/profile.d/http_proxy.sh':
      owner => root,
      group => root,
      mode => '0644',
      content => template('team_linux/http_proxy.erb'),
    }

  } else {
    file { '/etc/profile.d/http_proxy.sh':
      ensure  => 'absent'
    }
  }
}
