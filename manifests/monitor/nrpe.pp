class ffnord::monitor::nrpe ( $allowed_hosts
                            ) {
  package { 
    'nagios-nrpe-server': 
      ensure => installed,
      notify => [Service['nagios-nrpe-server']],
      require => [File['/etc/nagios/nrpe_local.cfg']];
    'cron-apt': 
      ensure => installed;
  } 

  service {
    'nagios-nrpe-service':
       ensure => running,
       enable => true;
  }

  file { 
    '/etc/nagios/nrpe_local.cfg': 
      ensure => file, 
      mode => '0644',
      owner => 'root',
      group => 'root',
      content => template('ffnord/etc/nagios/nrpe_local.cfg.erb');
  }
}
