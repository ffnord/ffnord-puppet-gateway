define ffnord::radvd (
    $mesh_ipv6_address,
    $mesh_ipv6_prefix,
    $mesh_ipv6_prefixlen
  ) {

  include ffnord::radvd::base
  include ffnord::resources::radvd

  $interface = $name

  File['/etc/radvd.conf.d']
  ->
  file { "/etc/radvd.conf.d/interface-${name}.conf": 
       ensure => file,
       content => template('ffnord/etc/radvd.conf.erb');
  }  
  ->
  Class[ffnord::resources::radvd]
  -> 
  Service[radvd]
}

class ffnord::radvd::base () {

  if defined(Class['ffnord::monitor::nrpe']){
    file {
      "/etc/nagios/nrpe.d/check_radvd.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_radvd]=/usr/lib/nagios/plugins/check_procs -w 2:2 -c 2:2 -C radvd"),
        require => [Package['nagios-nrpe-server']],
        notify => [Service['nagios-nrpe-server']];
    }
  }

  file { 
    '/etc/radvd.conf.d':
      ensure => directory,
      mode => "0755";
  }
  package { 
    'radvd': 
      ensure => installed,
      require => File['/etc/radvd.conf.d']; 
  }
  service { 
    'radvd': 
      enable => true, 
      ensure => running,
      hasrestart => true,
      require => [File['/etc/radvd.conf.d'],Package['radvd']]; 
  }
}
