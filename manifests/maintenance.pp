class ffnord::maintenance (
  $maintenance = $ffnord::params::maintenance
) inherits ffnord::params {
  include ffnord::resources::ffnord

  Class['ffnord::resources::ffnord'] ->

  file_line {
    'ffnord::config::maintenance':
       path => '/etc/ffnord',
       match => '^MAINTENANCE=.*',
       line => "MAINTENANCE=${maintenance}"
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
