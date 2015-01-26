define ffnord::dhcpd (
  $mesh_code,

  $ipv4_address,
  $ipv4_network,
  $ipv4_netmask,

  $ranges = [],
  $dns_servers = [],
  ) {

  include ffnord::dhcpd::base
  include ffnord::dhcpd::service

  if $ranges != [] {

    file { "/etc/dhcp/interface-${name}.conf":
      ensure => file,
      content => template("ffnord/etc/dhcp/interface.erb"),
      require => [Package['isc-dhcp-server']],
      notify => [Service['isc-dhcp-server']];
    } 

    file_line { "ffnord::dhcpd::${name}-rule":
      path => '/etc/dhcp/dhcpd.conf',
      line => "include \"/etc/dhcp/interface-${name}.conf\";",
      require => [File['/etc/dhcp/dhcpd.conf']],
      notify => [Service['isc-dhcp-server']];
    }
    
    ffnord::monitor::zabbix::check_script {
      "${mesh_code}_dhcppool":
        mesh_code => $mesh_code,
        scriptname => "dhcp-pool-usage-percent";
    }
  }
}

class ffnord::dhcpd::base {

  ffnord::monitor::nrpe::check_command {
    "dhcpd":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C dhcpd';
  }

  package { 
    'isc-dhcp-server': 
      ensure => installed;
  }

  file {
    "/etc/dhcp/dhcpd.conf":
      ensure => file,
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/ffnord/etc/dhcp/dhcpd.conf',
      require => [Package['isc-dhcp-server']],
      notify => [Service['isc-dhcp-server']];
  }
  
  ffnord::firewall::service { 'dhcpd':
    chains => ['mesh'],
    ports  => ['67','68'],
    protos => ['udp'];
  }
}

class ffnord::dhcpd::service {
  service { 
    'isc-dhcp-server': 
      ensure => running,
      hasrestart => true,
      enable => true;
  }
}

define ffnord::dhcpd::static (
  $static_git, # git repo with static file
) {
  include ffnord::dhcpd::base

  $static_name = $name

  file{
    "/etc/dhcp/statics/":
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755',
      require => Package['isc-dhcp-server'];
  }

  vcsrepo { "/etc/dhcp/statics/${static_name}/":
    ensure   => present,
    provider => git,
    source   => $static_git,
    require  => [
      File["/etc/dhcp/statics/"],
    ];
  }

  file{
    "/etc/dhcp/statics/${static_name}/.git/hooks/post-merge":
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      content => "#!/bin/sh\n/usr/local/bin/update-statics reload",
      require => Vcsrepo["/etc/dhcp/statics/${static_name}/"];
  }

  file_line {
    "static-${static_name}":
      path => "/etc/dhcp/interface-br-${static_name}.conf",
      line => "include \"/etc/dhcp/statics/${static_name}/static.conf\";",
      require => [
        Vcsrepo["/etc/dhcp/statics/${static_name}/"],
        File["/etc/dhcp/interface-br-${static_name}.conf"]
      ];
  }

  file {
    '/usr/local/bin/update-statics':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0755',
     source => 'puppet:///modules/ffnord/usr/local/bin/update-statics',
     require =>  Vcsrepo["/etc/dhcp/statics/${static_name}/"];
  }

  cron {
    'update-statics':
      command => '/usr/local/bin/update-statics pull',
      user => root,
      minute => [0,30],
      require => File['/usr/local/bin/update-statics'];
  }
}
