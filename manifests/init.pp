class ffnord( $site_code
            , $site_name

            , $icvpn = false
            , $icvpn_as
            , $icvpn_name
            , $icvpn_keyfile
            , $icvpn_ipv4
            , $icvpn_ipv6


            , $dhcprange_start
            , $dhcprange_end
            ) {
}

define ffnord::mesh( $mesh_name # "Freifunk Entenhausen"
                  , $mesh_code # "ffeh"
                  , $mesh_mac  # "52:54:00:bd:e6:d4"
                  , $mesh_prefix_ipv6
                  , $mesh_prefix_ipv4
                  , $mesh_ipv6
                  , $mesh_ipv4 = "0.0.0.0"

                  , $fastd_secret
                  , $fastd_port
                  ) {
  ffnord::bridge { "bridge_${mesh_code}":
    mesh_name => $mesh_name,
    mesh_code => $mesh_code,
    mesh_ipv4 => $mesh_ipv4,
    mesh_ipv6 => $mesh_ipv6,
    mesh_prefix_ipv6 => $mesh_prefix_ipv6,
    mesh_prefix_ipv4 => $mesh_prefix_ipv4;
  } ->
  ffnord::fastd { "fastd_${mesh_code}":
    mesh_name => $mesh_name,
    mesh_code => $mesh_code,
    mesh_mac  => $mesh_mac,
    
    fastd_secret => $fastd_secret,
    fastd_port   => $fastd_port,
    fastd_peers_git => 'git://freifunk.in-kiel.de/fastd-peer-keys.git';
  }
}
