################################################################################
# Implement role, set provisioning/state to ready, or log missing requirements
################################################################################
class team_linux::role::postgresql14 inherits team_linux::profile::parameters {
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {

    # see parameters # $pgsqlvers = lookup({ name => 'team_linux::pgsqlvers', value_type => String, merge => 'first', default_value => undef  })
    $compvers  = String($facts['postgresmodule'])

    if $pgsqlvers {

      require team_linux::meta_profile::baseline
      contain team_linux::profile::postgresql14
      # make absolutely sure postgres gets installed before the component module 
      # tries to install the wrong version
      # debug # notify { "Module enabled ${facts['postgresmodule']}, requested version: ${pgsqlvers}":}
      #if "$facts['postgresmodule']X" == "${pgsqlvers}X" {
      if "${compvers}X" == "${pgsqlvers}X" {
        contain team_linux::profile::postgreshiera
        contain team_linux::profile::postgresql_conf
      }
      if $facts['os']['family'] == 'redhat' and $rhelmajor == 8 {
        if $facts['disks']["$appdisk"] != undef {
  
          Class['::team_linux::meta_profile::baseline'] ->
          Class['team_linux::profile::postgresql14']
  
          if "$facts['postgresmodule']" == "${pgsqlvers}" {
            # Now the component module may configure things
            Class['team_linux::profile::postgresql'] ->
            Class['team_linux::profile::postgreshiera']
  
            Class['team_linux::profile::postgreshiera'] ->
            Class['team_linux::profile::postgresql_conf']
          }
  
        } else {
          # one or more prerequisites failed, log
          if $facts['disks']["$appdisk"] == undef { notify{ "Data disk $appdisk not found, skipping install of $cmdb['role']": } }
        }
      } else {
        fail( "This role requires RHEL 8" )
      }
    } else {
      fail ( "No version set for the DNF PostgreSQL module to use!" )
      }
    }
  }
