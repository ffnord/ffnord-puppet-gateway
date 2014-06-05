class ffnord::resources::sysctl {
  file {
    '/etc/sysctl.d/routing.conf':
      ensure => file,
      mode => "0644",
      source => 'puppet:///modules/ffnord/etc/sysctl.d/routing.conf',
      notify => Exec['sysctl load routing.conf'];
  }

  exec {
    'sysctl load routing.conf':
     command => "/sbin/sysctl -p /etc/sysctl.d/routing.conf";
  }
}
