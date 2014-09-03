class ffnord::bird6 (
  $router_id = $ffnord::params::router_id,
  $icvpn_as  = $ffnord::params::icvpn_as
) inherits ffnord::params {
 

  if defined(Class['ffnord::monitor::nrpe']){
    file {
      "/etc/nagios/nrpe.d/check_bird6.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_bird6]=/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C bird6\n"),
        require => [Package['nagios-nrpe-server']],
        notify => [Service['nagios-nrpe-server']];
    }
  }

  package { 
    'bird6':
      ensure => installed;
  }
 
  file {
    '/etc/bird/bird6.conf.d/':
      ensure => directory,
      mode => "0755",
      owner => root,
      group => root,
      require => File['/etc/bird/bird6.conf'];
    '/etc/bird/':
      ensure => directory,
      mode => '0755';
    '/etc/bird/bird6.conf':
      ensure => file,
      mode => "0644",
      content => template("ffnord/etc/bird/bird6.conf.erb"),
      require => [Package['bird6'],File['/etc/bird/']];
    '/etc/bird6.conf':
      ensure => link,
      target => '/etc/bird/bird6.conf',
      require => File['/etc/bird/bird6.conf'],
      notify => Service['bird6'];
  } 

  service { 
    'bird6': 
      ensure => running,
      enable => true,
      restart => "/usr/sbin/birdc6 configure",
      require => Package['bird6'],
      subscribe => File['/etc/bird/bird6.conf'];
  }

  ffnord::firewall::service { "bird6":
    ports  => ['179'],
    protos => ['tcp'],
    chains => ['mesh']
  }

}

define ffnord::bird6::mesh (
  $mesh_code,

  $mesh_ipv4_address,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings

  $icvpn_as,

  $site_ipv6_prefix,
  $site_ipv6_prefixlen,
) {

  include ffnord::bird6

  file_line { "bird6-${mesh_code}-include":
    path => '/etc/bird/bird6.conf',
    line => "include \"/etc/bird/bird6.conf.d/${mesh_code}.conf\";",
    require => File['/etc/bird/bird6.conf'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/${mesh_code}.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.interface.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird6']],
    notify  => File_line["bird6-${mesh_code}-include"];
  }
}

define ffnord::bird6::icvpn (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ffnord::bird6
  include ffnord::resources::meta

  $icvpn_name = $name

  class { 'ffnord::tinc': 
    tinc_name    => $icvpn_name,
    tinc_keyfile => $tinc_keyfile,

    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,

    icvpn_peers  => $icvpn_peerings;
  }

  file_line { 
    "icvpn-template":
      path => '/etc/bird/bird6.conf',
      line => 'include "/etc/bird/bird6.conf.d/icvpn-template.conf";',
      require => File['/etc/bird/bird6.conf'],
      notify  => Service['bird6'];
    "icvpn-include":
      path => '/etc/bird/bird6.conf',
      line => 'include "/etc/bird/bird6.conf.d/icvpn-peers.conf";',
      require => [
        File['/etc/bird/bird6.conf'],
        Class['ffnord::resources::meta']
      ],
      notify  => Service['bird6'];
    "ffnord::config::icvpn_exclude":
      path => '/etc/ffnord',
      match => '^ICVPN_EXCLUDE=.*',
      line => "ICVPN_EXCLUDE=${icvpn_exclude_peerings}",
      before => [
        Class['ffnord::resources::meta'],
        Service['bird6']
      ];
    "ffnord::config::icvpn":
      path => '/etc/ffnord',
      match => '^ICVPN=.*',
      line => "ICVPN=1",
      before => [
        Class['ffnord::resources::meta'],
        Service['bird6']
      ];
  } 

  # Process meta data from tinc directory
  file { "/etc/bird/bird6.conf.d/icvpn-template.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.icvpn-template.conf.erb"),
    require => [ 
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6'],
      Class['ffnord::tinc'],
    ],
    notify  => [
      File_line['icvpn-include'],
      File_line['icvpn-template']
    ];
  } 
}
