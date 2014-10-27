class ffnord::rsyslog {
  package {
    'rsyslog':
      ensure => installed;
    'logrotate':
      ensure => installed;
  }
  
  service {
    'rsyslog':
      ensure => running,
      enable => true,
      hasrestart => true,
      require => [Package['rsyslog']];
  }

  file {
    '/etc/rsyslog.d':
      ensure => directory,
      mode => '0755',
      owner => 'root',
      group => 'root';
    '/etc/rsyslog.d/local0.conf':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      source => 'puppet:///modules/ffnord/etc/rsyslog.d/local0.conf',
      notify => Service['rsyslog'];
    '/etc/rsyslog.d/local7.conf':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      source => 'puppet:///modules/ffnord/etc/rsyslog.d/local7.conf',
      notify => Service['rsyslog'];
    '/etc/rsyslog.d/dhcp.conf':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      source => 'puppet:///modules/ffnord/etc/rsyslog.d/dhcp.conf',
      notify => Service['rsyslog'];
    '/etc/rsyslog.d/fastd.conf':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      source => 'puppet:///modules/ffnord/etc/rsyslog.d/fastd.conf',
      notify => Service['rsyslog'];
    '/etc/logrotate.d/fastd':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      source => 'puppet:///modules/ffnord/etc/logrotate.d/fastd';
   '/var/log/fastd/':
      ensure => directory,
      mode => '0755',
      owner => 'root',
      group => 'root';
  }
}
