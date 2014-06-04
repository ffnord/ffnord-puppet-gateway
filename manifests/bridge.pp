define ffnord::bridge( $mesh_code
                    , $mesh_name
                    , $mesh_prefix_ipv6
                    , $mesh_prefix_ipv4
                    , $mesh_ipv6
                    , $mesh_ipv4

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
      notify  => Ffnord::Monitor::Vnstat::Device["br-${mesh_code}"];
  } ->
  Class[ffnord::resources::sysctl]
}
