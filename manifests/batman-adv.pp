define ffnord::batman-adv(
  $mesh_code,
  $mesh_hop_penalty,
  $batman_it = 5000,
  $batman_version = $::class::params::batman_version
) {
  include ffnord::resources::batman-adv
  include ffnord::firewall

  file {
    "/etc/network/interfaces.d/${mesh_code}-batman":
    ensure => file,
    content => template('ffnord/etc/network/mesh-batman.erb'),
    require => $batman_version ? {
      14 => [Package['batctl'],Package['batman-adv-dkms']],
      default => [Package['batctl']]
    }
  }

  file_line {
  "root_bashrc_bat${mesh_code}":
    path => '/root/.bashrc',
    line => "alias batctl-${mesh_code}='batctl -m bat-${mesh_code}'"
  }

  ffnord::monitor::zabbix::check_script {
    "${mesh_code}_gwmode":
      mesh_code => $mesh_code,
      scriptname => 'batman-gateway-mode-enabled',
      sudo => true;
    "${mesh_code}_maxmetric":
      mesh_code => $mesh_code,
      scriptname => 'batman-maximum-gateway-metric',
      sudo => true;
    "${mesh_code}_gwcount":
      mesh_code => $mesh_code,
      scriptname => 'batman-visible-gateway-count',
      sudo => true;
  }

  ffnord::firewall::device { "bat-${mesh_code}":
    chain => 'bat'
  }
}
