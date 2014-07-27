class ffnord::monitor::vnstat () {

  if defined(Class['ffnord::monitor::nrpe']){
    file {
      "/etc/nagios/nrpe.d/check_vnstatd":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_vnstatd]=/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C vnstatd\n"),
        notify => [Service['nagios-nrpe-server']];
    }
  }

  package { 
    'vnstat': 
      ensure => installed; 
  }

  service {
    'vnstat':
      ensure  => running,
      enable  => true,
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
