define ffnord::bridge( $mesh_code
                    , $mesh_name
                    , $mesh_prefix_ipv6
                    , $mesh_prefix_ipv4
                    , $mesh_ipv6
                    , $mesh_ipv4

                    ) {
  include ffnord::resources::network

  file {
    "/etc/network/interfaces.d/${mesh_code}-bridge":
      ensure => file, content => template('ffnord/etc/network/mesh-bridge.erb');
  } -> 
  exec {
    "start_bridge_interface_${mesh_code}":
      command => "/sbin/ifup br-${mesh_code}",
      unless  => "/bin/ip link dev br-${mesh_code}";
  }
}
