class ffnord::tinc (
  $tinc_name,
  $tinc_keyfile,

  $icvpn_ipv4_address,
  $icvpn_ipv6_address,

  $icvpn_peers = [],
) {
  package {
    'tinc':
      ensure => installed;
  }

  service {
    'tinc':
      ensure => running,
      enable => true,
      require => [ Package['tinc'], File['/etc/tinc/icvpn/tinc.conf'] ],
      subscribe => File['/etc/tinc/icvpn/tinc.conf'];
  }


  file {
    '/etc/tinc/icvpn/tinc.conf':
      ensure  => file,
      content => template('ffnord/etc/tinc/icvpn/tinc.conf.erb'),
      require => Vcsrepo['/etc/tinc/icvpn/'];
    '/etc/tinc/icvpn/rsa_key.priv':
      ensure  => file,
      source  => $tinc_keyfile,
      require => Vcsrepo['/etc/tinc/icvpn/'];
    '/etc/tinc/icvpn/tinc-up':
      ensure  => file,
      content => template('ffnord/etc/tinc/icvpn/tinc-up.erb'),
      mode => '0755';
    '/etc/tinc/icvpn/tinc-down':
      ensure  => file,
      content => template('ffnord/etc/tinc/icvpn/tinc-down.erb'),
      mode => '0755';
  }

  vcsrepo { "/etc/tinc/icvpn/":
    ensure   => present,
    provider => git,
    source   => "https://github.com/sargon/icvpn.git",
    require => Package['tinc']
  }

  

  # TODO Cronjob entry for enabling icvpn key updates
}
