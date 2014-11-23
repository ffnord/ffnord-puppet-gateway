class ffnord::bird (
  $router_id = $ffnord::params::router_id,
  $icvpn_as  = $ffnord::params::icvpn_as
) inherits ffnord::params {

  require ffnord::resources::repos
 
  ffnord::monitor::nrpe::check_command {
    "bird":
      command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C bird';
  }

  package { 
    'bird':
      ensure => installed,
      require => [
        File['/etc/apt/preferences.d/bird'],
        Apt::Source['debian-backports']
      ];
  }
 
  file {
    '/etc/bird/bird.conf.d/':
      ensure => directory,
      mode => "0755",
      owner => root,
      group => root,
      require => File['/etc/bird/bird.conf'];
# the following two definitions raise a duplicate definition warning with bird6
#   '/etc/bird/':
#     ensure => directory,
#     mode => '0755';
#   '/etc/apt/preferences.d/bird':
#     ensure => file,
#     mode => "0644",
#     owner => root,
#     group => root,
#     source => "puppet:///modules/ffnord/etc/apt/preferences.d/bird";
    '/etc/bird/bird.conf':
      ensure => file,
      mode => "0644",
      content => template("ffnord/etc/bird/bird.conf.erb"),
      require => [Package['bird'],File['/etc/bird/']];
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

  ffnord::firewall::service { "bird":
    ports  => ['179'],
    protos => ['tcp'],
    chains => ['mesh']
  }

}

define ffnord::bird::mesh (
  $mesh_code,

  $mesh_ipv4_address,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings

  $icvpn_as,

  $site_ipv4_prefix,
  $site_ipv4_prefixlen,
) {

  include ffnord::bird

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

define ffnord::bird::icvpn (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ffnord::bird
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
      path => '/etc/bird/bird.conf',
      line => 'include "/etc/bird/bird.conf.d/icvpn-template.conf";',
      require => File['/etc/bird/bird.conf'],
      notify  => Service['bird'];
    "icvpn-include":
      path => '/etc/bird/bird.conf',
      line => 'include "/etc/bird/bird.conf.d/icvpn-peers.conf";',
      require => [
        File['/etc/bird/bird.conf'],
        Class['ffnord::resources::meta']
      ],
      notify  => Service['bird'];
  } 

  ffnord::resources::ffnord::field {
    "ICVPN": value => '1';
    "ICVPN_EXCLUDE": value => "${icvpn_exclude_peerings}";
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
