class ffnord::tinc (
  $tinc_name,
  $tinc_keyfile,

  $icvpn_ipv4_address,
  $icvpn_ipv6_address,

  $icvpn_peers = [],
) {
  if($lsbdistcodename=="wheezy"){
    package {
      'tinc':
        ensure => installed,
        require => [
          File['/etc/apt/preferences.d/tinc'],
          Apt::Source['debian-backports']
        ];
    }
  } else {
    package {
      'tinc':
        ensure => installed,
    }
  }

  service {
    'tinc':
      ensure => running,
      enable => true,
      require => [
        Package['tinc'], 
        File['/etc/tinc/icvpn/tinc.conf'],
        File_line['icvpn-auto-boot']
      ],
      subscribe => File['/etc/tinc/icvpn/tinc.conf'];
  }

  ffnord::monitor::nrpe::check_command  {
    "tinc_icvpn":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C tincd -a "-n icvpn"';
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
      ensure => link,
      target => "/etc/tinc/icvpn/scripts/post-merge",
      require => Vcsrepo['/etc/tinc/icvpn/'],
      mode => '0755';
  }
  if($lsbdistcodename=="wheezy") {
    file {
      '/etc/apt/preferences.d/tinc':
            ensure => file,
            mode => "0644",
            owner => root,
            group => root,
            source => "puppet:///modules/ffnord/etc/apt/preferences.d/tinc";
    }
  }

  file_line {
    'icvpn-auto-boot':
      path => '/etc/tinc/nets.boot',
      line => "icvpn",
      require => Package['tinc'];
  }

  vcsrepo { "/etc/tinc/icvpn/":
    ensure   => present,
    provider => git,
    source   => "https://github.com/freifunk/icvpn.git",
    require => Package['tinc']
  }

  ffnord::etckeeper::ignore {
    "/etc/tinc/icvpn/":
  }

  cron {
   'update-icvpn':
     command => 'cd /etc/tinc/icvpn/ && git pull -q',
     user    => root,
     minute  => '0',
     hour    => '6',
     require => Vcsrepo['/etc/tinc/icvpn/'];
  }

  exec { "update-icvpn-once":
    command => "/etc/tinc/icvpn/scripts/post-merge",
    cwd => "/etc/tinc/icvpn",
    unless => "/bin/grep -c ConnectTo /etc/tinc/icvpn/tinc.conf",
    require => Vcsrepo['/etc/tinc/icvpn/'],
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
