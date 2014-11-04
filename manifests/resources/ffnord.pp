# Ensure existence of global configuration file
# for various scripts from this module.
class ffnord::resources::ffnord {
  file { '/etc/ffnord':
    ensure => file,
    mode => "0644";
  }
}
