define ffnord::bridge( $mesh_code
                    , $mesh_name
                    , $mesh_ipv6_address
                    , $mesh_ipv6_prefix
                    , $mesh_ipv6_prefixlen
                    , $mesh_ipv4_address
                    , $mesh_ipv4_netmask
                    , $mesh_ipv4_prefix
                    , $mesh_ipv4_prefixlen

                    , $dhcp_ranges = []

                    , $dns_servers = []

                    ) {
  include ffnord::resources::network
  include ffnord::resources::sysctl

  ffnord::monitor::vnstat::device { "br-${mesh_code}": }

  Class['ffnord::resources::network'] ->
  file {
    "/etc/network/interfaces.d/${mesh_code}-bridge":
      ensure => file, 
      content => template('ffnord/etc/network/mesh-bridge.erb');
  } -> 
  exec {
    "start_bridge_interface_${mesh_code}":
      command => "/sbin/ifup br-${mesh_code}",
      unless  => "/bin/ip link show dev br-${mesh_code} 2> /dev/null",
      before  => Ffnord::Monitor::Vnstat::Device["br-${mesh_code}"],
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ffnord::resources::sysctl] 
                 ];
  } ->
  ffnord::firewall::device { "br-${mesh_code}":
    chain => "mesh"
  } ->
  ffnord::firewall::forward { "br-${mesh_code}":
    chain => "mesh"
  }
}
