class ffnord::maintenance (
  $maintenance = $ffnord::params::maintenance
) inherits ffnord::params {
  include ffnord::resources::ffnord

  Class['ffnord::resources::ffnord'] ->

  ffnord::resources::ffnord::field {
    'MAINTENANCE': value => $maintenance;
  }

  file {
    '/usr/local/bin/maintenance':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      source => 'puppet:///modules/ffnord/usr/local/bin/maintenance';
  }
}
