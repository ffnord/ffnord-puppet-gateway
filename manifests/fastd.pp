define ffnord::fastd( $mesh_name
                     , $mesh_code
                     , $mesh_mac

                     , $fastd_secret
                     , $fastd_port

                     , $fastd_peers_git
                     ) {
  #validate_re($mesh_mac, '^de:ad:be:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}$')

  include ffnord::resources::fastd
  include ffnord::resources::fastd::auto_fetch_keys

  if defined(Class['ffnord::monitor::nrpe']){
    file {
      "/etc/nagios/nrpe.d/check_fastd_${mesh_code}.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_fastd_${mesh_code}]=/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C fastd -a \"${mesh_code}-mesh-vpn\"\n"),
        require => [Package['nagios-nrpe-server']],
        notify => [Service['nagios-nrpe-server']];
    }
  }

  file {
    "/etc/fastd/${mesh_code}-mesh-vpn/":
      ensure =>directory,
             require => Package[ffnord::resources::fastd];
    "/etc/fastd/${mesh_code}-mesh-vpn/fastd.conf":
      ensure => file,
             notify => Service[ffnord::resources::fastd],
             content => template('ffnord/etc/fastd/fastd.conf.erb');
    "/etc/fastd/${mesh_code}-mesh-vpn/secret.conf":
      ensure  => file,
              mode    => '0600',
              content => inline_template('secret "<%= @fastd_secret %>";');
  } ->
  ffnord::batman-adv { "ffnord_batman_adv_${mesh_code}":
    mesh_code => $mesh_code;
  } ->
  vcsrepo { "/etc/fastd/${mesh_code}-mesh-vpn/peers":
    ensure   => present,
    provider => git,
    source   => $fastd_peers_git,
    notify   => Class[ffnord::resources::fastd::auto_fetch_keys];
  } ->
  ffnord::firewall::service { "fastd-${mesh_code}":
    ports  => [$fastd_port],
    protos => ['udp'],
    chains => ['wan']
  }

}
