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
       require => [
         Package['nagios-nrpe-server'],
         File['/etc/nagios/nrpe.d/allowed_hosts.cfg'],
         File['/etc/nagios/nrpe.d/check_apt.cfg']
       ];
  }

  file { 
    '/etc/nagios/nrpe.d/allowed_hosts.cfg': 
      ensure => file, 
      mode => '0644',
      owner => 'root',
      group => 'root',
      require => Package['nagios-nrpe-server'],
      content => template('ffnord/etc/nagios/nrpe.d/allowed_hosts.cfg.erb');
  }

  file { 
    '/etc/nagios/nrpe.d/check_apt.cfg':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      require => Package['nagios-nrpe-server'],
      source => "puppet:///modules/ffnord/etc/nagios/nrpe.d/check_apt.cfg";
  }

  ffnord::firewall::service { 'nrpe':
    ports => ['5666'],
    chains => ['wan'];
  }
}

define ffnord::monitor::nrpe::check_command (
  $command
) {
  if defined(Class['ffnord::monitor::nrpe']) {
    file {
      "/etc/nagios/nrpe.d/check_${name}.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_${name}]=${command}\n"),
        require => Package['nagios-nrpe-server'],
        notify => Service['nagios-nrpe-server'];
    }
  }
}
