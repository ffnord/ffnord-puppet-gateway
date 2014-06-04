class ffnord::monitor::nrpe ( $allowed_hosts
                            ) {
  package { 'nagios-nrpe-server': ensure => installed; 
            'cron-apt': ensure => installed;
          }
  -> file { '/etc/nagios/nrpe_local.cfg': ensure => file, content => template('ffnord/etc/nagios/nrpe_local.cfg.erb'); }
}
