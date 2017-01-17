class ffnord::resources::network {

  file {
    '/etc/network/interfaces.d':
      ensure => directory;
  } ->
  file_line {
    'ffnord::resources::network::if':
      path => '/etc/network/interfaces',
      line => 'source /etc/network/interfaces.d/*';
  } ->
  package {
    'ifupdown':
      ensure => installed;
    'bridge-utils':
      ensure => installed;
  }

  file_line {
    '/etc/iproute2/rt_tables':
      path =>'/etc/iproute2/rt_tables',
      line => '42 mesh';
  }
}
