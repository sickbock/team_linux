class team_linux::profile::zabbix7server_conf  {

# Configure the Zabbix server:
#https://www.zabbix.com/documentation/current/en/manual/appendix/config/zabbix_server
# At least, increase the CacheSize 
# https://www.zabbix.com/forum/zabbix-troubleshooting-and-problems/382799-cachesize-and-other-tuning

  $zabbix_server_cache = lookup ( { name => 'team_linux::zabbix_server_cache', default_value => '256M' } )
  $zabbix_server_logsize = lookup ( { name => 'team_linux::zabbix_server_logsize', default_value => '10' } )
  $zabbix_server_startpollers = lookup ( { name => 'team_linux::zabbix_server_startpollers', default_value => '10' } )
  $zabbix_server_startpreprocessors = lookup ( { name => 'team_linux::zabbix_server_startpreprocessors', default_value => '30' } )
  $zabbix_server_startpollersunreachable = lookup ( { name => 'team_linux::zabbix_server_startpollersunreachable', default_value => '10' } )
  $zabbix_server_startdiscoverers = lookup ( { name => 'team_linux::zabbix_server_startdiscoverers', default_value => '10' } )
  $zabbix_server_startpingers = lookup ( { name => 'team_linux::zabbix_server_startpingers', default_value => '10' } )
  $zabbix_server_housekeepingfrequency = lookup ( { name => 'team_linux::zabbix_server_housekeepingfrequency', default_value => '5' } )
  $zabbix_server_historycachesize = lookup ( { name => 'team_linux::zabbix_server_historycachesize', default_value => '64M' } )
  $zabbix_server_historyindexcachesize = lookup ( { name => 'team_linux::zabbix_server_historyindexcachesize', default_value => '32M' } )
  $zabbix_server_trendcachesize = lookup ( { name => 'team_linux::zabbix_server_trendcachesize', default_value => '24M' } )
  $zabbix_server_valuecachesize = lookup ( { name => 'team_linux::zabbix_server_valuecachesize', default_value => '256M' } )
  $zabbix_server_timeout = lookup ( { name => 'team_linux::zabbix_server_timeout', default_value => '30' } )

    file_line { 'CacheSize':
      ensure  => present,
      line    => "CacheSize=${zabbix_server_cache}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^CacheSize=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'LogFileSize':
      ensure  => present,
      line    => "LogFileSize=${zabbix_server_logsize}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^LogFileSize=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'StartPollers':
      ensure  => present,
      line    => "StartPollers=${zabbix_server_startpollers}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^StartPollers=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'StartPreprocessors':
      ensure  => present,
      line    => "StartPreprocessors=${zabbix_server_startpreprocessors}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^StartPreprocessors=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'StartPollersUnreachable':
      ensure  => present,
      line    => "StartPollersUnreachable=${zabbix_server_startpollersunreachable}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^StartPollersUnreachable=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'StartPingers':
      ensure  => present,
      line    => "StartPingers=${zabbix_server_startpingers}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^StartPingers=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'StartDiscoverers':
      ensure  => present,
      line    => "StartDiscoverers=${zabbix_server_startdiscoverers}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^StartDiscoverers=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'HousekeepingFrequency':
      ensure  => present,
      line    => "HousekeepingFrequency=${zabbix_server_housekeepingfrequency}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^HousekeepingFrequency=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'HistoryCacheSize':
      ensure  => present,
      line    => "HistoryCacheSize=${zabbix_server_historycachesize}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^HistoryCacheSize=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'HistoryIndexCacheSize':
      ensure  => present,
      line    => "HistoryIndexCacheSize=${zabbix_server_historyindexcachesize}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^HistoryIndexCacheSize=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'TrendCacheSize':
      ensure  => present,
      line    => "TrendCacheSize=${zabbix_server_trendcachesize}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^TrendCacheSize=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'ValueCacheSize':
      ensure  => present,
      line    => "ValueCacheSize=${zabbix_server_valuecachesize}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^ValueCacheSize=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }

    file_line { 'Timeout':
      ensure  => present,
      line    => "Timeout=${zabbix_server_timeout}",
      path    => '/etc/zabbix/zabbix_server.conf',
      match   => '^Timeout=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service['zabbix-server'],
    }


    service{ 'zabbix-server':
      ensure  => running,
      enable => 'true',
      require => Package['httpd'],
    }

}

