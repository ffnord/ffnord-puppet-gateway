define ffnord::fastd( $mesh_code,
  $batman_code,
  $mesh_interface, # may not be more than 10 characters
  $mesh_mac,
  $mesh_hop_penalty = 60, # hop penalty for batman advanced
  $vpn_mac,
  $mesh_mtu = 1280,
  $fastd_secret,
  $fastd_port,
  $fastd_peers_git,
  $fastd_verify = ''
) {
  #validate_re($mesh_mac, '^de:ad:be:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}$')

  include ffnord::resources::fastd
  include ffnord::resources::fastd::auto_fetch_keys

  ffnord::monitor::nrpe::check_command {
    "fastd_${mesh_interface}":
      command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C fastd -a \"${mesh_interface}-mvpn\"";
  }

  ffnord::monitor::zabbix::check_script {
    "${mesh_interface}_fastdcons":
      mesh_code  => $mesh_code,
      scriptname => 'fastd_connections',
      sudo       => true;
    "${mesh_interface}_fastdcons6":
      mesh_code  => $mesh_code,
      scriptname => 'fastd_connections6',
      sudo       => true;
  }

  file {
  "/etc/fastd/${mesh_interface}-mvpn/":
    ensure  =>directory,
    require => Package[ffnord::resources::fastd];
  "/etc/fastd/${mesh_interface}-mvpn/fastd.conf":
    ensure  => file,
    notify  => Service[ffnord::resources::fastd],
    content => template('ffnord/etc/fastd/fastd.conf.erb');
  "/etc/fastd/${mesh_interface}-mvpn/secret.conf":
    ensure => file,
    source => $fastd_secret,
    mode   => '0600',
  }
  if ! defined(Ffnord::Batman-Adv["ffnord_batman_adv_${mesh_code}"]) {
      ffnord::batman-adv { "ffnord_batman_adv_${mesh_code}":
        mesh_code        => $mesh_code,
        mesh_hop_penalty => $mesh_hop_penalty;
      }
  }
  vcsrepo { "/etc/fastd/${mesh_interface}-mvpn/peers":
    ensure   => present,
    provider => git,
    require  => Ffnord::Batman-adv["ffnord_batman_adv_${mesh_code}"],
    source   => $fastd_peers_git,
    notify   => Class[ffnord::resources::fastd::auto_fetch_keys];
  } ->
  ffnord::firewall::service { "fastd-${mesh_interface}":
    ports  => [$fastd_port],
    protos => ['udp'],
    chains => ['wan']
  }

  file {
  "/etc/fastd/${mesh_interface}-mvpn/peers/.git/hooks/post-merge":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\n/usr/local/bin/update-fastd-keys reload",
    require => Vcsrepo["/etc/fastd/${mesh_interface}-mvpn/peers"];
  }

  file_line {
  "root_bashrc_fastd_query_${mesh_interface}":
    path => '/root/.bashrc',
    line => "alias fastd-query-${mesh_interface}='FASTD_SOCKET=/var/run/fastd-status.${mesh_interface}.sock fastd-query'"
  }

  ffnord::etckeeper::ignore { "/etc/fastd/${mesh_interface}-mvpn/peers/": }

}
