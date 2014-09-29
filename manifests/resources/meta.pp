class ffnord::resources::meta {

  vcsrepo { 
     '/var/lib/icvpn-meta/':
       ensure => present,
       provider => git,
       source => "https://github.com/freifunk/icvpn-meta.git";
     '/opt/icvpn-scripts/':
       ensure => present,
       provider => git,
       source => "https://github.com/freifunk/icvpn-scripts.git",
       require => [
         Vcsrepo['/var/lib/icvpn-meta/'],
         Package['python-yaml']
       ];
  }

  package {
    'python-yaml':
      ensure => installed;
  }

  file { 
    '/usr/local/bin/update-meta':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      source => "puppet:///modules/ffnord/usr/local/bin/update-meta";
  }

  exec {
    'update-meta':
      command => '/usr/local/bin/update-meta',
      require => [
        Vcsrepo['/var/lib/icvpn-meta/'],
        File['/usr/local/bin/update-meta'],
      ];
  }

  cron {
    'update-icvpn-meta':
      command => '/usr/local/bin/update-meta',
      user => root,
      minute => '0',
      require => [
        File['/usr/local/bin/update-meta']
      ];
  }
}
