class ffnord::resources::ffnord {
  file { '/etc/ffnord':
    ensure => file,
    mode => "0644";
  }
}
