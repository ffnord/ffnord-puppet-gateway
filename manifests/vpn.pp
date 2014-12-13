class ffnord::vpn ( 
  $gw_control_ip     = "8.8.8.8",     # Control ip addr 
  $gw_bandwidth      = 54,            # How much bandwith we should have up/down per mesh interface
) {

  include ffnord::resources::ffnord

  class {
    'ffnord::resources::checkgw':
      gw_control_ip => $gw_control_ip,
      gw_bandwidth => $gw_bandwidth,
      gw_vpn_interface => $gw_vpn_interface,
  }
}

class ffnord::vpn::provider () {

  include ffnord::firewall

  service {'openvpn':
    ensure  => running,
    hasrestart => true,
    require => Package['openvpn'],
    notify => Class['ffnord::vpn'];
  }
 
  package { 'openvpn':
    ensure => installed;
  }

  class { 'ffnord::vpn': }
 
  ffnord::monitor::nrpe::check_command {
    "openvpn_anonvpn":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C openvpn -a "ovpn-anonvpn"';
  }

  ffnord::monitor::vnstat::device { 'tun-anonvpn': }

  ffnord::firewall::forward { 'tun-anonvpn':
    chain => 'mesh'
  }

  # Define Firewall rule for masquerade
  file {
    '/etc/iptables.d/910-Masquerade-tun-anonvpn':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0644',
     content => 'ip4tables -t nat -A POSTROUTING -o tun-anonvpn -j MASQUERADE',
     require => [File['/etc/iptables.d/']],
  }
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
      owner => "root",
      group => "root",
      mode => "0644",
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
      owner => "root",
      group => "root",
      mode => "0755",
      require => [Package['openvpn']];
    '/etc/openvpn/hideio/hideio.conf': 
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0644",
      content => template("ffnord/etc/openvpn/hideio.conf.erb"),
      require => [File["/etc/openvpn/hideio"],Package['openvpn']];
    '/etc/openvpn/hideio/password':
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0640",
      content => template("ffnord/etc/openvpn/password.erb"),
      require => [File['/etc/openvpn/hideio']];
    '/etc/openvpn/hideio/TrustedRoot.pem':
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0644",
      source => "puppet:///modules/ffnord/etc/openvpn/hideio.root.pem",
      require => [File['/etc/openvpn/hideio']];
    '/etc/openvpn/anonvpn-up.sh':
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0755",
      source => "puppet:///modules/ffnord/etc/openvpn/anonvpn-up.sh",
      require => [File['/etc/openvpn/hideio']];
  }
}
