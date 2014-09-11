class ffnord::alfred () { 
  vcsrepo { '/opt/alfred':
    ensure => present,
    provider => git,
    source => "http://git.open-mesh.org/alfred.git";
  }

  file { '/etc/init.d/alfred':
    ensure => file,
    mode => "0755",
    source => "puppet:///modules/ffnord/etc/init.d/alfred";
  }

  package { 
    'build-essential':
      ensure => installed;
    'pkg-config':
      ensure => installed;
    'libgps-dev':
      ensure => installed;
    'python3':
      ensure => installed;
    'ethtool':
      ensure => installed;
  }

  exec { 'alfred':
    command => "/usr/bin/make",
    cwd => "/opt/alfred/",
    require => [Vcsrepo['/opt/alfred'],Package['build-essential'],Package['pkg-config'],Package['libgps-dev']];
  }

  service { 'alfred':
    ensure => running,
    hasrestart => true,
    enable => true,
    require => [Exec['alfred'],File['/etc/init.d/alfred']];
   }

  vcsrepo { '/opt/alfred-announce':
    ensure => present,
    provider => git,
    source => "https://github.com/ffnord/ffnord-gateway-alfred.git",
    require => Package['python3'],Package['ethtool']
  }

  cron {
   'update-alfred-announce':
     command => 'PATH=/opt/alfred/:/bin:/usr/bin:/sbin:$PATH /opt/alfred-announce/announce.sh',
     user    => root,
     minute  => '*',
     require => [Vcsrepo['/opt/alfred-announce'], Vcsrepo['/opt/alfred']];
  }
  
  ffnord::firewall::service { 'alfred':
    protos => ["udp"],
    chains => ["mesh","bat"],
    ports => ['16962'],
  }
}
