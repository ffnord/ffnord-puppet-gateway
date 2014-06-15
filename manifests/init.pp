define ffnord::mesh(
  $mesh_name,        # Name of your community, e.g.: Freifunk Entenhausen
  $mesh_code,        # Code of your community, e.g.: ffeh
  $mesh_as,          # AS of your community
  $mesh_mac,         # mac address mesh device: 52:54:00:bd:e6:d4
  $mesh_prefix_ipv4, # ipv4 netmask of your mesh network, in cid
  $mesh_prefix_ipv6, # ipv6 netmask of your mesh network, in cidr notation.
  $mesh_ipv6,        # ipv6 address of mesh device
  $mesh_ipv4,        # ipv4 address of mesh device
  $mesh_peerings,    # path to the local peerings description yaml file

  $fastd_secret,     # fastd secret
  $fastd_port,       # fastd port

  $dhcp_ranges = [], # dhcp pool
  $dns_servers = [], # other dns servers in your network
) {

  # TODO We should handle parameters in a param class pattern.

  include ffnord::ntp

  ffnord::bridge { "bridge_${mesh_code}":
    mesh_name => $mesh_name,
    mesh_code => $mesh_code,
    mesh_ipv4 => $mesh_ipv4,
    mesh_ipv6 => $mesh_ipv6,
    mesh_prefix_ipv6 => $mesh_prefix_ipv6,
    mesh_prefix_ipv4 => $mesh_prefix_ipv4,
  } ->
  Class['ffnord::ntp'] ->
  ffnord::dhcpd { "br-${mesh_code}":
    mesh_code    => $mesh_code,
    ipv4_address => $mesh_ipv4,
    ipv4_netmask => $mesh_prefix_ipv4,
    ranges       => $dhcp_ranges,
    dns_servers  => $dns_servers;
  } ->
  ffnord::fastd { "fastd_${mesh_code}":
    mesh_name => $mesh_name,
    mesh_code => $mesh_code,
    mesh_mac  => $mesh_mac,
    fastd_secret => $fastd_secret,
    fastd_port   => $fastd_port,
    fastd_peers_git => 'git://freifunk.in-kiel.de/fastd-peer-keys.git';
  } ->
  ffnord::radvd { "br-${mesh_code}":
    ipv6_address => $mesh_ipv6,
    ipv6_prefix  => $mesh_prefix_ipv6;
  } ->
  ffnord::bird6::mesh { "bird6-${mesh_code}":
    mesh_code => $mesh_code,
    mesh_ipv4_address => $mesh_ipv4,
    mesh_ipv6_address => $mesh_ipv6,
    mesh_peerings => $mesh_peerings,
    site_ipv6_prefix => $mesh_prefix_ipv6,
    icvpn_as => $mesh_as;
  }
  # ffnord::named
  # ffnord::bird{4}
  # ffnord::opkg::mirror
  # ffnord::firmware mirror
}
