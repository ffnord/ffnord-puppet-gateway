class ffnord::bird4 (
  $router_id = $ffnord::params::router_id,
  $icvpn_as  = $ffnord::params::icvpn_as
) inherits ffnord::params {

  require ffnord::resources::repos
 
  ffnord::monitor::nrpe::check_command {
    "bird":
      command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C bird';
  }

  if($lsbdistcodename=="wheezy"){
    package { 
      'bird':
        ensure => installed,
        require => [
          File['/etc/apt/preferences.d/bird'],
          Apt::Source['debian-backports']
        ];
    }
  } else {
    package { 
      'bird':
        ensure => installed;
    }
  }
  file {
    '/etc/bird/bird.conf.d/':
      ensure => directory,
      mode => "0755",
      owner => root,
      group => root,
      require => File['/etc/bird/'];
    '/etc/bird/bird.conf':
      ensure => file,
      mode => "0644",
      content => template("ffnord/etc/bird/bird.conf.erb"),
      require => [
        Package['bird'],
        File['/etc/bird/'],
        File['/etc/bird/bird.conf.d/']
      ],
      before => Class['ffnord::resources::meta'];
    '/etc/bird.conf':
      ensure => link,
      target => '/etc/bird/bird.conf',
      require => File['/etc/bird/bird.conf'],
      notify => Service['bird'];
  } 

  service {
    'bird':
      ensure => running,
      enable => true,
      hasstatus => false,
      restart => "/usr/sbin/birdc configure",
      require => Package['bird'],
      subscribe => File['/etc/bird/bird.conf'];
  }

  include ffnord::resources::bird
}

define ffnord::bird4::mesh (
  $mesh_code,

  $mesh_ipv4_address,
  $range_ipv4,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings

  $icvpn_as,

  $site_ipv4_prefix,
  $site_ipv4_prefixlen,
) {

  include ffnord::bird4

  file_line { "bird-${mesh_code}-include":
    path => '/etc/bird/bird.conf',
    line => "include \"/etc/bird/bird.conf.d/${mesh_code}.conf\";",
    require => File['/etc/bird/bird.conf'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/${mesh_code}.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird.interface.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-${mesh_code}-include"],
      Service['bird']
    ]
  }
}

define ffnord::bird4::icvpn (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ffnord::bird4
  include ffnord::resources::meta
  include ffnord::icvpn

  $icvpn_name = $name

  file_line { 
    "icvpn-template":
      path => '/etc/bird/bird.conf',
      line => 'include "/etc/bird/bird.conf.d/icvpn-template.conf";',
      require => File['/etc/bird/bird.conf'],
      notify  => Service['bird'];
  }->
  file_line {
    "icvpn-include":
      path => '/etc/bird/bird.conf',
      line => 'include "/etc/bird/bird.conf.d/icvpn-peers.conf";',
      require => [
        File['/etc/bird/bird.conf'],
        Class['ffnord::resources::meta']
      ],
      notify  => Service['bird'];
  } 

  # Process meta data from tinc directory
  file { "/etc/bird/bird.conf.d/icvpn-template.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird.icvpn-template.conf.erb"),
    require => [ 
      File['/etc/bird/bird.conf.d/'],
      Package['bird'],
      Class['ffnord::tinc'],
    ],
    notify  => [
      Service['bird'],
      File_line['icvpn-include'],
      File_line['icvpn-template']
    ];
  } 
}
