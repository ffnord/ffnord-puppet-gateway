class ffnord::ntp () {
  package { 
    'ntp':
      ensure => installed,
  } 
  ->
  file { 
    '/etc/ntp.conf':
      ensure => file,
      mode => "0644",
      owner => "root",
      group => "root",
      source => "puppet:///modules/ffnord/etc/ntp.conf",
  } 
  ->
  service { 
    'ntp':
      enable => true,
      hasrestart => true,
      ensure => running;
  }
  ->
  ffnord::firewall::service { 'ntpd':
    ports => ['123'],
    protos => ['udp'],
    chains => ['mesh'],
    rate_limit => true,
    rate_limit_seconds => 3600,
    rate_limit_hitcount => 10, 
  }
}
