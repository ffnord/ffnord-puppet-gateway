define ffnord::batman-adv( $mesh_code
                         , $batman_it = 5000
                         ) {
  include ffnord::resources::batman-adv
  include ffnord::firewall

  file {
    "/etc/network/interfaces.d/${mesh_code}-batman":
    ensure => file,
    content => template('ffnord/etc/network/mesh-batman.erb'),
    require => [Package['batctl'],Package['batman-adv-dkms']];
  }

  file_line {
   'root_bashrc_batffki':
     path => '/root/.bashrc',
     line => "alias batctl-${mesh_code}='batctl -m bat-${mesh_code}'"
  }

  # Define Firewall rules for services on bat interfaces, e.g. alfred
  # introducing the "bat" chain
  file {
    '/etc/iptables.d/002-batman-chains':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0644',
     content => "ip46tables -N bat-forward\nip46tables -N bat-input",
     require => [File['/etc/iptables.d/']],
  }


  file {
    '/etc/iptables.d/900-batman-DROP':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0644',
     content => "ip46tables -A bat-forward -j DROP\nip46tables -A bat-input -j DROP",
     require => [File['/etc/iptables.d/']],
  }

  ffnord::firewall::device { "bat-${mesh_code}":
    chain => "bat"
  } 
}
