class ffnord::ntp () {

  package {
    'ntp':
      ensure => installed,
  }

  file {
    '/etc/ntp.conf':
      ensure => file,
      mode => "0644",
      owner => "root",
      group => "root",
      source => "puppet:///modules/ffnord/etc/ntp.conf",
      require => Package['ntp'];
  }

  service {
    'ntp':
      enable => true,
      hasrestart => true,
      ensure => running,
      require => [
        Package['ntp'],
        File['/etc/ntp.conf']
      ]
  }

  ffnord::firewall::service { 'ntpd':
    ports => ['123'],
    protos => ['udp'],
    chains => ['mesh'],
    rate_limit => true,
    rate_limit_seconds => 3600,
    rate_limit_hitcount => 10,
  }
}

define ffnord::ntp::allow(
  $ipv4_net, # ipv4 address in cidr notation, e.g. 10.35.0.1/19
  $ipv6_net, # ipv6 address in cidr notation, e.g. fd35:f308:a922::ff00/64
) {

  include ffnord::ntp

  $ipv4_prefix   = inline_template("<%= IPAddr.new(@ipv4_net) %>")
  $ipv4_prefixlen = inline_template("<%= @ipv4_net.split('/')[1] %>")
  $ipv4_netmask   = inline_template("<%= IPAddr.new('255.255.255.255').mask(@ipv4_prefixlen)%>")

  $ipv6_prefix    = inline_template("<%= IPAddr.new(@ipv6_net) %>")
  $ipv6_prefixlen = inline_template("<%= @ipv6_net.split('/')[1] %>")
  $ipv6_netmask   = inline_template("<%= IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff').mask(@ipv6_prefixlen)%>")

  file_line {
    "ntp_restrict_v4_${name}":
    path => '/etc/ntp.conf',
    line => "restrict ${ipv4_prefix} mask ${ipv4_netmask} nomodify notrap nopeer",
    require => File['/etc/ntp.conf'];
  }

  file_line {
    "ntp_restrict_v6_${name}":
    path => '/etc/ntp.conf',
    line => "restrict -6 ${ipv6_prefix} mask ${ipv6_netmask} nomodify notrap nopeer",
    require => File['/etc/ntp.conf'];
  }

}
