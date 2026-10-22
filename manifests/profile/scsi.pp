class team_linux::profile::scsi inherits team_linux::profile::parameters {

  $timeout = 180
  $eh_timeout = 60
  $ioscheduler = 'cfq'

  file{ '/etc/udev/rules.d/62-scsi-timeout.rules':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('team_linux/62-scsi-timeout.rules.erb'),
    notify  => Exec['trigger_scsi_timeout'],
  }

  file{ '/etc/udev/rules.d/63-scsi-diskconfig.rules':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('team_linux/63-scsi-diskconfig.rules.erb'),
    notify  => Exec['trigger_scsi_timeout'],
  }  

  exec{ 'trigger_scsi_timeout':
    command => "/sbin/udevadm trigger",
    refreshonly => true,
  }
}
