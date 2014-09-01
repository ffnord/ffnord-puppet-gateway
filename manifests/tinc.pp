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

  if defined(Class['ffnord::monitor::nrpe']){
    file {
      "/etc/nagios/nrpe.d/check_tinc_icvpn.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("command[check_tinc_icvpn]=/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C tinc -a \"-n icvpn\"\n"),
        require => [Package['nagios-nrpe-server']],
        notify => [Service['nagios-nrpe-server']];
    }
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
      require => Vcsrepo['/etc/tinc/icvpn/'],
      mode => '0755';
    '/etc/tinc/icvpn/tinc-down':
      ensure  => file,
      content => template('ffnord/etc/tinc/icvpn/tinc-down.erb'),
      require => Vcsrepo['/etc/tinc/icvpn/'],
      mode => '0755';
    '/etc/tinc/icvpn/.git/hooks/post-merge':
      ensure => file,
      source => "/etc/tinc/icvpn/scripts/post-merge",
      require => Vcsrepo['/etc/tinc/icvpn/'],
      mode => '0755';
  }

  file_line {
    'icvpn-auto-boot':
      path => '/etc/tinc/nets.boot',
      line => "icvpn";
  }

  vcsrepo { "/etc/tinc/icvpn/":
    ensure   => present,
    provider => git,
    source   => "https://github.com/sargon/icvpn.git",
    require => Package['tinc']
  }

  cron {
   'update-icvpn':
     command => 'cd /etc/tinc/icvpn/ && git pull -q',
     user    => root,
     minute  => '0',
     hour    => '6',
     require => Vcsrepo['/etc/tinc/icvpn/'];
  }

  ffnord::firewall::device { "icvpn":
    chain => 'mesh'
  }

  ffnord::firewall::forward { "icvpn":
    chain => 'mesh'
  }

  ffnord::firewall::service { "tincd":
    ports  => ['655'],
    chains => ['wan']
  }
}
