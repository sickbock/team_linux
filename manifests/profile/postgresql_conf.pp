class team_linux::profile::postgresql_conf inherits team_linux::profile::parameters {

  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    # see parameters # $pgsqlvers = lookup({ name => 'team_linux::pgsqlvers', value_type => String, merge => 'first', default_value => '12'  })
    $netaccess = lookup({ name => 'team_linux::psqlnetaccess', merge => 'first', default_value => false  })
    $maxconn   = lookup({ name => 'team_linux::psqlmaxconnections', merge => 'first', default_value => 100  })
    $shbuffers = lookup({ name => 'team_linux::psqlshared_buffers', merge => 'first', default_value => 0.30  })
    $workmem   = lookup({ name => 'team_linux::psqlwork_mem', merge => 'first', default_value => 0.03  })
    $mworkmem  = lookup({ name => 'team_linux::psqlmwork_mem', merge => 'first', default_value => 0.04  })
    $passwencr = lookup({ name => 'team_linux::psqlpasswordencryption', merge => 'first', default_value => 'md5'  })
    $rdata_dir = lookup({ name => 'team_linux::remove_line_data_dir', merge => 'first', default_value => false  })

    $ram_size   = $facts['memory']['system']['total_bytes']
    #notify {"RAM: $ram_size":}
    $buffersf   = ( ( $ram_size * $shbuffers ) / 1024);
    #notify {"Buffers float: $buffersf":}
    $buffers    = Integer(inline_template('<%= @buffersf.to_i %>'))
    #notify {"Shared buffers: $buffers":}
    $work_memf  = (($ram_size * $workmem)/1024);
    #notify {"Work memory float: $work_memf":}
    $work_mem   = Integer(inline_template('<%= @work_memf.to_i %>'))
    #notify {"Work memory: $work_mem":}
    $mwork_memf = (($ram_size * $mworkmem)/1024);
    #notify {"Minimal Work memory float: $mwork_memf":}
    $mwork_mem  = Integer(inline_template('<%= @mwork_memf.to_i %>'))
    #notify {"Minimal Work memory: $mwork_mem":}

    # make sure postgres is installed in the right version:
    if $facts['postgresmodule'] == "${pgsqlvers}" {
      if $maxconn > 100 {
        file_line { 'max_connections':
          ensure  => present,
          line    => "max_connections=${maxconn}",
          path    => '/var/lib/pgsql/data/postgresql.conf',
          match   => '^max_connections',
          replace => true,
          replace_all_matches_not_matching_line => true,
          notify  => Exec['systemctl_reaload_postgresql'],
        }
      } 
      if $buffers > 128 {
        file_line { 'max_buffers':
          ensure  => present,
          line    => "shared_buffers=${buffers}kB",
          path    => '/var/lib/pgsql/data/postgresql.conf',
          match   => '^shared_buffers',
          replace => true,
          replace_all_matches_not_matching_line => true,
          notify  => Exec['systemctl_reaload_postgresql'],
        }
      } 
      if $work_mem > 64 {
        file_line { 'work_mem':
          ensure  => present,
          line    => "work_mem=${work_mem}kB",
          path    => '/var/lib/pgsql/data/postgresql.conf',
          match   => '^work_mem',
          replace => true,
          replace_all_matches_not_matching_line => true,
          notify  => Exec['systemctl_reaload_postgresql'],
        }
      } 
      if $mwork_mem > 1024 {
        file_line { 'mwork_mem':
          ensure  => present,
          line    => "maintenance_work_mem=${mwork_mem}kB",
          path    => '/var/lib/pgsql/data/postgresql.conf',
          match   => '^maintenance_work_mem',
          replace => true,
          replace_all_matches_not_matching_line => true,
          notify  => Exec['systemctl_reaload_postgresql'],
        }
      } 
      if $netaccess { # manage network access 
        file_line { 'psqlnet':
          ensure  => present,
          line    => "listen_addresses='*'",
          path    => '/var/lib/pgsql/data/postgresql.conf',
          match   => '^listen_addresses',
          replace => true,
          replace_all_matches_not_matching_line => true,
          notify  => Exec['systemctl_reaload_postgresql'],
        }
      }
      if $rdata_dir { # Remove line data_dir for PostgreSQL upgrade
        file_line { 'data_directory':
          ensure            => absent,
          line              => "data_directory",
          path              => '/var/lib/pgsql/data/postgresql.conf',
          #match             => '^data_directory',
          match_for_absence => true,
        }
      }
      if $passwencr { # Set encryption type
        file_line { 'password_encryption':
          ensure            => present,
          line              => "password_encryption=${passwencr}",
          path              => '/var/lib/pgsql/data/postgresql.conf',
          match             => '^password_encryption',
          replace           => true,
          replace_all_matches_not_matching_line => true,
          match_for_absence => true,
          notify            => Exec['systemctl_reaload_postgresql'],
        }
      }
    } 

    exec { 'systemctl_reaload_postgresql':
      command     => 'systemctl reload postgresql',
      refreshonly => true,
      onlyif      => 'test -x /usr/bin/postgres',
      path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    }

  }

}
