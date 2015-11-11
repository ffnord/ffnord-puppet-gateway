# Global parameters for this host
class { 
  'ffnord::params':
    router_id => "10.35.0.1", # The id of this router, probably the ipv4 address
                              # of the mesh device of the providing community
    icvpn_as => "65035",      # The as of the providing community
    wan_devices => ['eth0'],   # A array of devices which should be in the wan zone

    wmem_default => 87380,     # Define the default socket send buffer
    wmem_max     => 12582912,  # Define the maximum socket send buffer
    rmem_default => 87380,     # Define the default socket recv buffer
    rmem_max     => 12582912,  # Define the maximum socket recv buffer

    max_backlog  => 5000,      # Define the maximum packages in buffer
}

# You can repeat this mesh block for every community you support
ffnord::mesh { 
  'mesh_ffgc':
    mesh_name    => "Freifunk Gotham City",
    mesh_code    => "ffgc",
    mesh_as      => 65035,
    mesh_mac     => "de:ad:be:ef:de:ad",
    vpn_mac      => "de:ad:be:ff:de:ad",
    mesh_ipv6    => "fd35:f308:a922::ff00/64,
    mesh_ipv4    => "10.35.0.1/19",
    mesh_mtu     => "1280",
    range_ipv4   => "10.35.0.0/16",
    mesh_peerings => "/root/mesh_peerings.yaml",

    fastd_secret => "/root/fastd_secret.key",
    fastd_port   => 11280,
    fastd_peers_git => 'git://somehost/peers.git',

    dhcp_ranges => [ '10.35.0.2 10.35.0.254'
                   , '10.35.1.1 10.35.1.254'
                   , '10.35.2.2 10.35.2.254'
                   , '10.35.3.2 10.35.3.254'
                   , '10.35.4.2 10.35.4.254'
                   ],
    dns_servers => [ '10.35.5.1'
                   , '10.35.10.1'
                   , '10.35.15.1'
                   , '10.35.20.1'
                   ]
}

ffnord::named::zone {
  'ffgc': zone_git => 'git://somehost/ffgc-zone.git';
}

ffnord::dhcpd::static {
  'ffgc': static_git => 'git://somehost/ffgc-static.git';
}

class {
  'ffnord::vpn::provider::hideio':
    openvpn_server => "nl-7.hide.io",
    openvpn_port   => 3478,
    openvpn_user   => "wayne",
    openvpn_password => "brucessecretpw",
}

ffnord::fastd { 
  'ffgc_old':
    mesh_code       => "ffgc",
    mesh_interface  => "ffgc-old",
    mesh_mac        => "de:ad:be:ee:de:ad",
    vpn_mac         => "de:ad:be:fe:de:ad",
    mesh_mtu        => 1426,
    fastd_secret    => "/root/fastd_secret.conf",
    fastd_port      => 10000,
    fastd_peers_git => '/vagrant/fastd/gc/'
}

ffnord::icvpn::setup {
  'gotham_city0':
    icvpn_as => 65035,
    icvpn_ipv4_address => "10.112.0.1",
    icvpn_ipv6_address => "fec0::a:cf:0:35",
    icvpn_exclude_peerings     => [gotham],
    tinc_keyfile       => "/root/tinc_rsa_key.priv"
}

class {
  'ffnord::monitor::munin':
    host => '10.35.31.1'
}

class {
  'ffnord::monitor::nrpe':
    allowed_hosts => '10.35.31.1'
}

class {
  'ffnord::monitor::zabbix':
    zabbixserver => "10.35.31.1";
}

class { 'ffnord::alfred': master => true }

class { 'ffnord::etckeeper': }

# Useful packages
package {
  ['vim','tcpdump','dnsutils','realpath','screen','htop','tcpdump','mlocate','tig']:
    ensure => installed;
}
