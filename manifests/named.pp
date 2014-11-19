class ffnord::named () {

  include ffnord::resources::meta

  ffnord::monitor::nrpe::check_command {
    "named":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C named';
  }

  package {
    'bind9':
      ensure => installed;
  }

  service {
    'bind9':
      ensure => running,
      enable => true,
      hasrestart => true,
      restart => '/usr/sbin/rndc reload',
      require => [
        Package['bind9'],
        File['/etc/bind/named.conf.options'],
        File_line['icvpn-meta'],
        Class['ffnord::resources::meta']
      ]
  }

  file {
    '/etc/bind/named.conf.options':
      ensure  => file,
      source  => "puppet:///modules/ffnord/etc/bind/named.conf.options",
      require => [Package['bind9']],
      notify  => [Service['bind9']];
  }

  file_line {
    'icvpn-meta':
       path => '/etc/bind/named.conf',
       line => 'include "/etc/bind/named.conf.icvpn-meta";',
       before => Class['ffnord::resources::meta'],
       require => [
         Package['bind9']
       ];
  }

  ffnord::firewall::service { 'named':
    chains => ['mesh'],
    ports  => ['53'],
    protos => ['udp','tcp'];
  }
}

## ffnord::named::zone
# Define a custom zone and receive the zone file from a git repository.
#
# The here defined resource is assuming that the configuration file
# is named '${zone_name}.conf'.
define ffnord::named::zone (
  $zone_git, # git repo with zone files
  $exclude_meta = '' # optinal exclude zone from icvpn-meta
) {
  include ffnord::named

  $zone_name = $name

  file{
    "/etc/bind/zones/":
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755',
      require => Package['bind9'];
  }

  vcsrepo { "/etc/bind/zones/${zone_name}/":
    ensure   => present,
    provider => git,
    source   => $zone_git,
    require  => [
      File["/etc/bind/zones/"],
    ];
  }

  file{
    "/etc/bind/zones/${zone_name}/.git/hooks/post-merge":
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      content => "#!/bin/sh\n/usr/local/bin/update-zones reload",
      require => Vcsrepo["/etc/bind/zones/${zone_name}/"];
  }

  file_line {
    "zone-${zone_name}":
      path => '/etc/bind/named.conf',
      line => "include \"/etc/bind/zones/${zone_name}/${zone_name}.conf\";",
      require => [
        Vcsrepo["/etc/bind/zones/${zone_name}/"]
      ];
  }

  file {
    '/usr/local/bin/update-zones':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0755',
     source => 'puppet:///modules/ffnord/usr/local/bin/update-zones',
     require =>  Vcsrepo["/etc/bind/zones/${zone_name}/"];
  }

  cron {
    'update-zones':
      command => '/usr/local/bin/update-zones pull',
      user => root,
      minute => [0,30],
      require => File['/usr/local/bin/update-zones'];
  }

  if $exclude_meta != '' {
    ffnord::resources::meta::dns_zone_exclude { 
      "${exclude_meta}": 
        before => Exec['update-meta'];
    }
  }
}

define ffnord::named::mesh (
  $mesh_ipv4_address,
  $mesh_ipv4_prefix,
  $mesh_ipv4_prefixlen,
  $mesh_ipv6_address,
  $mesh_ipv6_prefix,
  $mesh_ipv6_prefixlen
) {

 include ffnord::named

 $mesh_code = $name

 # Extent the listen-on and listen-on-v6 lines in the options block
 exec { "${name}_listen-on":
   command => "/bin/sed -i -r 's/(listen-on .*)\\}/\\1 ${mesh_ipv4_address};}/' /etc/bind/named.conf.options",
   require => File['/etc/bind/named.conf.options'];
 }
 
 exec { "${name}_listen-on-v6":
   command => "/bin/sed -i -r 's/(listen-on-v6 .*)\\}/\\1 ${mesh_ipv6_address};}/' /etc/bind/named.conf.options",
   require => File['/etc/bind/named.conf.options'];
 }
}
