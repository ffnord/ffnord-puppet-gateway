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

  $ipv4_prefix    = ip_prefix($ipv4_net)
  $ipv4_prefixlen = ip_prefixlen($ipv4_net)
  $ipv4_netmask   = ip_netmask($ipv4_net)

  $ipv6_prefix    = ip_prefix($ipv6_net)
  $ipv6_prefixlen = ip_prefixlen($ipv6_net)
  $ipv6_netmask   = ip_netmask($ipv6_net)

  file_line {
    "ntp_restrict_v4_${name}":
    path => '/etc/ntp.conf',
    line => "restrict ${ipv4_prefix} mask ${ipv4_netmask} nomodify notrap nopeer",
    require => File['/etc/ntp.conf'];
  }

  file_line {
    "ntp_restrict_v6_${name}":
    path => '/etc/ntp.conf',
    line => "restrict ${ipv6_prefix} mask ${ipv6_netmask} nomodify notrap nopeer",
    require => File['/etc/ntp.conf'];
  }

}
