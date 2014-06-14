define ffnord::dhcpd (
  $mesh_code,

  $ipv4_address,
  $ipv4_netmask,

  $ranges = [],
  $dns_servers = [],
  ) {

  include ffnord::dhcpd::base
  include ffnord::dhcpd::service

  if $ranges != [] {

    $ipv4_network = inline_template("<%= IPAddr.new(@ipv4_address).mask(@ipv4_netmask) %>")

    Class[ffnord::dhcpd::base]
    ->
    file { "/etc/dhcp/interface-${name}.conf":
      ensure => file,
      content => template("ffnord/etc/dhcp/interface.erb");
    } ->
    file_line { "ffnord::dhcpd::${name}-rule":
      path => '/etc/dhcp/dhcpd.conf',
      line => "include \"/etc/dhcp/interface-${name}.conf\";",
      notify => Service[ffnord::dhcp];
    }
  }
}

class ffnord::dhcpd::base {
  package { 'isc-dhcp-server': ensure => installed; }
  ->
  file {
    "/etc/dhcp/dhcpd.conf":
      ensure => file,
      mode   => "0644",
      source => 'puppet:///modules/ffnord/etc/dhcp/dhcpd.conf';
  }
}

class ffnord::dhcpd::service {
  service { 'ffnord::dhcp': name => "isc-dhcp-server", ensure => running, enable => true; }
}
