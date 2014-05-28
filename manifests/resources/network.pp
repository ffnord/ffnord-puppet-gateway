class ffnord::resources::network {
  package { 'ffnord::ressource::network': name => "ifupdown", ensure => installed } 
  -> file { '/etc/network/interfaces.d': ensure => directory; }
}
