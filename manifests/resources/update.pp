# Common scripts for update scripts.
class ffnord::resources::update () {
  file {
    '/usr/local/include/ffnord-update.common':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => 'puppet:///modules/ffnord/usr/local/include/ffnord-update.common';
  }
}
