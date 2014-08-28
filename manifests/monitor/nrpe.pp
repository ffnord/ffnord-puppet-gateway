class ffnord::monitor::nrpe ( $allowed_hosts
                            ) {
  package { 
    'nagios-nrpe-server': 
      ensure => installed,
      notify => Service['nagios-nrpe-server'];
    'cron-apt': 
      ensure => installed;
  } 

  service {
    'nagios-nrpe-server':
       ensure => running,
       hasrestart => true,
       enable => true,
       require => [Package['nagios-nrpe-server'],File['/etc/nagios/nrpe_local.cfg']];
  }

  file { 
    '/etc/nagios/nrpe_local.cfg': 
      ensure => file, 
      mode => '0644',
      owner => 'root',
      group => 'root',
      require => Package['nagios-nrpe-server'],
      content => template('ffnord/etc/nagios/nrpe_local.cfg.erb');
  }

  ffnord::firewall::service { 'nrpe':
    ports => ['5666'],
    chains => ['wan'];
  }
}
