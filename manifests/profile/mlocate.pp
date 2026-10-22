class team_linux::profile::mlocate inherits team_linux::profile::parameters {
  # deep merge of prunepaths array
  $mlocate_prune_paths  = lookup({ name => 'team_linux::mlocate_prune_paths', value_type => Array[String], merge => 'deep', default_value => undef })

  $prune_str = $mlocate_prune_paths.join(' ')

  $package_name = 'mlocate'
  $conf_file    = '/etc/updatedb.conf'
  $template     = 'team_linux/updatedb.conf.erb'

  package { "${package_name}":
    ensure => installed,
  }

  file { "${conf_file}":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => "0644",
    content => template( $template)
  }
}
