class ffnord::resources::radvd {
  exec { 'radvd.conf-build':
    command => '/bin/cat /etc/radvd.conf.d/* > /etc/radvd.conf';
  }
}
