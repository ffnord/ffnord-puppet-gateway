class ffnord::monitor::vnstat () {
  package { 
    'vnstat': 
      ensure => installed; 
  }

  service {
    'vnstat':
      ensure  => running,
      require => [Package['vnstat']];
  }
}

define ffnord::monitor::vnstat::device() {
  include ffnord::monitor::vnstat
 
  exec { "vnstat device ${name}":
    command => "/usr/bin/vnstat -u -i ${name}",
    require => [Package['vnstat']],
    notify => [Service['vnstat']];
  }
}
