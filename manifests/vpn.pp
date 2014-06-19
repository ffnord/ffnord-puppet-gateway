class ffnord::vpn ( 
  $gw_vpn_interface  = "tun-anonvpn", # Interface name for the anonymous vpn
  $gw_control_ip     = "8.8.8.8",     # Control ip addr 
  $gw_bandwidth      = 54,            # How much bandwith we should have up/down per mesh interface
) {

  include ffnord::resources::ffnord

  file {
    '/usr/local/bin/check-gateway':
      ensure => file,
      mode => "0755",
      source => 'puppet:///ffnord/usr/local/bin/check-gateway';
  }
  Class[ffnord::resources::ffnord] ->
  file_line { 
    "ffnord::config::gw_interface":
      path => '/etc/ffnord',
      line => "GW_VPN_INTERFACE=${gw_vpn_interface}";
    "ffnord::config::gw_control":
      path => '/etc/ffnord',
      line => "GW_CONTROL_IP=${gw_control_ip}";
    "ffnord::config::gw_bandwidth":
      path => '/etc/ffnord',
      line => "GW_BANDWIDTH=${gw_bandwidth}";
  } 
  cron {
   'check-gateway':
     command => '/usr/local/bin/check-gateway',
     user    => root,
     minute  => '*';
  }
}

class ffnord::vpn::provider () {
  service {'openvpn':
    ensure  => running,
    require => Package['openvpn'],
    notify => Class['ffnord::vpn'];
  }
 
  package { 'openvpn':
    ensure => installed;
  }

  class { 'ffnord::vpn': }
}

class ffnord::vpn::provider::mullvad () {
  # TODO
  include ffnord::vpn::provider
}

class ffnord::vpn::provider::hideio (
  $openvpn_server,
  $openvpn_port,
  $openvpn_user,
  $openvpn_password,
) {
  include ffnord::vpn::provider

  file { 
    '/etc/openvpn/anonvpn.conf': 
      ensure => link,
      target => "/etc/openvpn/hideio/hideio.conf",
      require => [File["/etc/openvpn/hideio/hideio.conf"],
                  File["/etc/openvpn/hideio/password"],
                  File["/etc/openvpn/hideio/TrustedRoot.pem"],
                  File["/etc/openvpn/anonvpn-up.sh"],
                  Package['openvpn'],
                 ],
      notify => [Service['openvpn']];
    '/etc/openvpn/hideio':
      ensure => directory,
      require => [Package['openvpn']];
    '/etc/openvpn/hideio/hideio.conf': 
      ensure => file,
      content => template("ffnord/etc/openvpn/hideio.conf.erb"),
      require => [File["/etc/openvpn/hideio"],Package['openvpn']];
    '/etc/openvpn/hideio/password':
      ensure => file,
      content => template("ffnord/etc/openvpn/password.erb"),
      require => [File['/etc/openvpn/hideio']];
    '/etc/openvpn/hideio/TrustedRoot.pem':
      ensure => file,
      source => "puppet:///ffnord/etc/openvpn/hideio.root.pem",
      require => [File['/etc/openvpn/hideio']];
    '/etc/openvpn/anonvpn-up.sh':
      ensure => file,
      source => "puppet:///ffnord/etc/openvpn/anonvpn-up.sh",
      require => [File['/etc/openvpn/hideio']];
  }
}
