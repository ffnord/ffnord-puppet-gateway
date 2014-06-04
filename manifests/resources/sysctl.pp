class ffnord::resources::sysctl {
  file {
    '/etc/sysctl.d/routing.conf':
      ensure => file,
      mode => "0644",
      source => 'puppet:///modules/ffnord/usr/local/bin/check-gateway';
  }
}
