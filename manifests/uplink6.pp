class ffnord::uplink6 ( 
) inherits ffnord::params {

  file_line {
    "v6uplink-template":
      path => '/etc/bird/bird6.conf',
      line => 'include "/etc/bird/bird6.conf.d/uplink.conf";',
      require => File['/etc/bird/bird6.conf'],
      notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/uplink.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.uplink.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6'],
    ],
    notify  => [
      Service['bird6'],
      File_line['v6uplink-template']
    ];
  }
}

define ffnord::uplink6::bgp (
  $local_ipv6,
  $remote_ipv6,
  $remote_as,
  $uplink_interface
) {

  include ffnord::bird6
  include ffnord::uplink6

  file_line {
    "v6uplink-${name}-include":
      path => '/etc/bird/bird6.conf.d/uplink.conf',
      line => "include \"/etc/bird/bird6.conf.d/uplink.${name}.conf\";",
      require => [
        File_line['v6uplink-template'],
      ],
      notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/uplink.${name}.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.uplink.peer.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6'],
    ],
    notify  => [
      Service['bird6'],
      File_line["v6uplink-${name}-include"],
      File_line['v6uplink-template']
    ];
  }  
}

define ffnord::uplink6::interface (
) {
  include ffnord::firewall

  ffnord::firewall::forward { "${name}":
    chain => 'mesh'
  }

  ffnord::firewall::device { "${name}":
    chain => 'mesh'
  } 
}

define ffnord::uplink6::tunnel (
) {
}
