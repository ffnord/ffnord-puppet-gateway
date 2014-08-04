class ffnord::rsyslog {
  package {
    'rsyslog':
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
      source => 'puppet:///modules/ffnord/etc/rsyslog.d/local0.conf';
    '/etc/rsyslog.d/dhcp.conf':
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      source => 'puppet:///modules/ffnord/etc/rsyslog.d/dhcp.conf';
  }
}
