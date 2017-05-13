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
    # todo: this doesn't work for alfred, that uses /bin/sh
    'GW_CONTROL_IP': value => "( ${gw_control_ips} )";
  }

  cron {
    'check-gateway':
      command => '/usr/local/bin/check-gateway',
      user    => root,
      minute  => '*';
  }
}
