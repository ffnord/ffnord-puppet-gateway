define ffnord::batman-adv( $mesh_code
                         , $batman_it = 5000
                         ) {
  include ffnord::resources::batman-adv

  file {
    "/etc/network/interfaces.d/${mesh_code}-batman":
    ensure => file,
    content => template('ffnord/etc/network/mesh-batman.erb'),
    require => [Package['batctl'],Package['batman-adv-dkms']];
  }

  file_line {
   'root_bashrc_batffki':
     path => '/root/.bashrc',
     line => "alias batctl-ffki='batctl -m bat-${mesh_code}'"
  }
}
