define ffnord::mesh(
  $mesh_name,         # Name of your community, e.g. 'Freifunk Gotham City'
  $mesh_code,         # Code of your community, e.g. 'ffgc'
  $mesh_as,           # AS of your community
  $mesh_mac,          # mac address mesh device: e.g. '52:54:00:bd:e6:d4'
  $vpn_mac,           # mac address vpn device, ideally != mesh_mac and unique
  $mesh_mtu = 1280,   # mtu used, default only suitable for fastd via ipv4
  $range_ipv4,        # ipv4 range allocated to community in cidr notation, e.g. '10.35.0.1/16'
  $mesh_ipv4,         # ipv4 address in cidr notation, e.g. '10.35.0.1/19'
  $mesh_ipv6,         # ipv6 address in cidr notation, e.g. 'fd35:f308:a922::ff00/64'
  $mesh_peerings,     # path to the local peerings description yaml file

  $fastd_peers_git,   # fastd peers
  $fastd_secret,      # fastd secret
  $fastd_port,        # fastd port
  $fastd_verify = '', # fastd verification override string for connection attempts, e.g. 'true' = accept all, '' = default (no override)

  $dhcp_ranges = [],  # dhcp pool
  $dns_servers = [],  # other dns servers in your network
  $mesh_hop_penalty = 60, # hop_penalty for gateway hops

  $fastd_igw_enable = false, # enable fastd inter gateway instance
  $fastd_igw_peers_git,      # fastd inter gateway peers
  $fastd_igw_secret,         # fastd inter gateway secret
  $fastd_igw_port,           # fastd inter gateway port
  $fastd_igw_verify = '',    # fastd backbone verification override

  $igw_mtu,           # fastd inter gateway verification override
  $igw_hop_penalty = 60, # hop_penalty for inter gateway traffic
) {

  # TODO We should handle parameters in a param class pattern.
  # TODO Handle all git repos and other external sources in
  #      a configuration class, so we can redefine sources.
  # TODO Update README

  include ffnord::ntp
  include ffnord::maintenance
  include ffnord::firewall

  # Determine ipv{4,6} network prefixes and ivp4 netmask
  $mesh_ipv4_prefix    = ip_prefix($mesh_ipv4)
  $mesh_ipv4_prefixlen = ip_prefixlen($mesh_ipv4)
  $mesh_ipv4_netmask   = ip_netmask($mesh_ipv4)
  $mesh_ipv4_address   = ip_address($mesh_ipv4)

  $mesh_ipv6_prefix    = ip_prefix($mesh_ipv6)
  $mesh_ipv6_prefixlen = ip_prefixlen($mesh_ipv6)
  $mesh_ipv6_address   = ip_address($mesh_ipv6)

  Class['ffnord::firewall'] ->
  ffnord::bridge { "bridge_${mesh_code}":
    mesh_name            => $mesh_name,
    mesh_code            => $mesh_code,
    mesh_ipv6_address    => $mesh_ipv6_address,
    mesh_ipv6_prefix     => $mesh_ipv6_prefix,
    mesh_ipv6_prefixlen  => $mesh_ipv6_prefixlen,
    mesh_ipv4_address    => $mesh_ipv4_address,
    mesh_ipv4_netmask    => $mesh_ipv4_netmask,
    mesh_ipv4_prefix     => $mesh_ipv4_prefix,
    mesh_ipv4_prefixlen  => $mesh_ipv4_prefixlen
  } ->
  Class['ffnord::ntp'] ->
  ffnord::ntp::allow { $mesh_code:
    ipv4_net => $mesh_ipv4,
    ipv6_net => $mesh_ipv6
  } ->
  ffnord::dhcpd { "br-${mesh_code}":
    mesh_code    => $mesh_code,
    ipv4_address => $mesh_ipv4_address,
    ipv4_network => $mesh_ipv4_prefix,
    ipv4_netmask => $mesh_ipv4_netmask,
    ranges       => $dhcp_ranges,
    dns_servers  => $dns_servers;
  } ->
  ffnord::fastd { "fastd_${mesh_code}":
    mesh_code       => $mesh_code,
    batman_code     => $mesh_code,
    mesh_interface  => $mesh_code,
    mesh_mac        => $mesh_mac,
    mesh_hop_penalty=> $mesh_hop_penalty,
    vpn_mac         => $vpn_mac,
    mesh_mtu        => $mesh_mtu,
    fastd_secret    => $fastd_secret,
    fastd_port      => $fastd_port,
    fastd_peers_git => $fastd_peers_git,
    fastd_verify    => $fastd_verify;
  } ->
  ffnord::radvd { "br-${mesh_code}":
    mesh_ipv6_address    => $mesh_ipv6_address,
    mesh_ipv6_prefix     => $mesh_ipv6_prefix,
    mesh_ipv6_prefixlen  => $mesh_ipv6_prefixlen;
  } ->
  ffnord::named::listen { $mesh_code:
    ipv4_address => $mesh_ipv4_address,
    ipv6_address => $mesh_ipv6_address,
  } ->
  ffnord::named::allow {
    "${mesh_code}_v4":
      ip_prefix    => $mesh_ipv4_prefix,
      ip_prefixlen => $mesh_ipv4_prefixlen;
    "${mesh_code}_v6":
      ip_prefix    => $mesh_ipv6_prefix,
      ip_prefixlen => $mesh_ipv6_prefixlen;
  }

  if $fastd_igw_enable {
    Class['ffnord::ntp'] -> ffnord::fastd { "fastd_igw_${mesh_code}":
      mesh_code       => "igw-${mesh_code}",
      batman_code     => $mesh_code,
      mesh_interface  => "igw-${mesh_code}",
      mesh_mac        => $mesh_mac,
      mesh_hop_penalty=> $igw_hop_penalty,
      vpn_mac         => $vpn_mac,
      mesh_mtu        => $igw_mtu,
      fastd_secret    => $fastd_igw_secret,
      fastd_port      => $fastd_igw_port,
      fastd_peers_git => $fastd_igw_peers_git,
      fastd_verify    => $fastd_igw_verify;
    }
  }

  if $ffnord::params::include_bird6 {
    ffnord::bird6::mesh { "bird6-${mesh_code}":
      mesh_code           => $mesh_code,
      mesh_ipv4_address   => $mesh_ipv4_address,
      mesh_ipv6_address   => $mesh_ipv6_address,
      mesh_peerings       => $mesh_peerings,
      site_ipv6_prefix    => $mesh_ipv6_prefix,
      site_ipv6_prefixlen => $mesh_ipv6_prefixlen,
      icvpn_as            => $mesh_as;
    }
  }
  if $ffnord::params::include_bird4 {
    ffnord::bird4::mesh { "bird4-${mesh_code}":
      mesh_code           => $mesh_code,
      mesh_ipv4_address   => $mesh_ipv4_address,
      range_ipv4          => $range_ipv4,
      mesh_ipv6_address   => $mesh_ipv6_address,
      mesh_peerings       => $mesh_peerings,
      site_ipv4_prefix    => $mesh_ipv4_prefix,
      site_ipv4_prefixlen => $mesh_ipv4_prefixlen,
      icvpn_as            => $mesh_as;
    }
  }

# ffnord::opkg::mirror
# ffnord::firmware mirror
}
