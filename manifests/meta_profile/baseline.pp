###############################################################################
#
# Basic Linux server configuration: to be consumed by 
#   - IAAS server role "baseline"
#   - any  other role for a specific server configuration (by any team)
#
################################################################################
class team_linux::meta_profile::baseline inherits team_linux::profile::parameters {
# no explicit depencency order:
  if String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) < 9 {
    contain team_linux::meta_profile::baseline_prepare_el8
    if $noderole != puppetpe_master and $noderole != puppetce_master {
      contain team_linux::profile::puppetagent

      Class['team_linux::meta_profile::baseline_prepare_el8'] ->
      Class['team_linux::profile::puppetagent']
    }
#    file { '/var/lib/provisioning':
#      ensure => 'directory',
#      mode => '0755',
#      owner => 'root',
#      group => 'root',
#    } ->
#    file { '/var/lib/provisioning/state':
#      ensure  => present,
#      mode    => '0644',
#      owner   => 'root',
#      group   => 'root',
#      content => 'ready',
#    }
  } elsif String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) == 9 {
    require team_linux::meta_profile::baseline_prepare_el9
    if $noderole != puppetpe_master and $noderole != puppetce_master {
      contain team_linux::profile::puppetagent

      Class['team_linux::meta_profile::baseline_prepare_el9'] ->
      Class['team_linux::profile::puppetagent']
    }
    
  } elsif String($facts['os']['family']) == 'RedHat' and Integer($facts['os']['release']['major']) == 10 {
    require team_linux::meta_profile::baseline_prepare_el10
    if $noderole != puppetpe_master and $noderole != puppetce_master {
      contain team_linux::profile::puppetagent

      Class['team_linux::meta_profile::baseline_prepare_el10'] ->
      Class['team_linux::profile::puppetagent']
    }
    
  } else {
    fail( "This role requires a supported version of RHEL" )
  }
  # correct file mode for /etc/yum.repos.d/redhat.repo (Satellite migration?)
  exec {'fix_/etc/yum.repos.d/redhat.repo':
    command  => 'rpm --setperms subscription-manager',
    onlyif   => 'test -f /etc/yum.repos.d/redhat.repo',
    unless   => "[[ $(/usr/bin/stat --format '%a' /etc/yum.repos.d/redhat.repo) -eq 644 ]]",
    provider => 'shell',
    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
  } 
}
