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
      source => 'puppet:///modules/ffnord/usr/local/bin/check-gateway';
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

  if defined(Class['ffnord::monitor::nrpe']){
    file {
      "/etc/nagios/nrpe.d/check_openvpn_anonvpn.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_openvpn_anonvpn]=/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C openvpn -a \"ovpn-anonvpn\"\n"),
        require => [Package['nagios-nrpe-server']],
        notify => [Service['nagios-nrpe-server']];
    }
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
