class team_linux::profile::shellconfig inherits team_linux::profile::parameters {

  $scriptroot = lookup({ name => 'linuxbeheerscripts::scriptroot', value_type => String, merge => 'deep', default_value => 'not_set' })
  $root_main  = lookup({ name => 'linuxbeheerscripts::root_main', value_type => String, merge => 'deep', default_value => 'not_set' })
  $user_main  = lookup({ name => 'linuxbeheerscripts::user_main', value_type => String, merge => 'deep', default_value => 'not_set' })
  $scriptdir  = lookup({ name => 'linuxbeheerscripts::scriptdir', value_type => String, merge => 'deep', default_value => 'not_set' })

  $root_paths = "$scriptroot/$root_main/$scriptdir"
  $user_paths = "$scriptroot/$user_main/$scriptdir"

    file{ '/root/.bash_profile':
    owner   => root,
    group   => root,
    mode    => '0640',
    content => template('team_linux/root_bash_profile.erb'),
  }

  file{ '/etc/profile.d/commonprofile.sh':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    =>  '0644',
    content => template('team_linux/commonprofile.erb'),
  }
}
