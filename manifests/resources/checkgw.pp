class ffnord::resources::checkgw (
  $gw_control_ips    = $ffnord::params::gw_control_ips,
  $gw_bandwidth      = 54,            # How much bandwith we should have up/down per mesh interface
) inherits ffnord::params {

  file {
    '/usr/local/bin/check-gateway':
      ensure => file,
      mode => '0755',
      source => 'puppet:///modules/ffnord/usr/local/bin/check-gateway';
  }

  ffnord::resources::ffnord::field {
    'GW_CONTROL_IP': value => "( ${gw_control_ip} )"; # TODO: this is not a top-scope variable!
  }

  cron {
    'check-gateway':
      command => '/usr/local/bin/check-gateway',
      user    => root,
      minute  => '*';
  }
}
