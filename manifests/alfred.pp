class ffnord::alfred (
  $master = false
) { 
  vcsrepo { '/opt/alfred':
    ensure => present,
    provider => git,
    revision => "6ffa009183cf5a223bf2198f7711b143b1e80109",
    source => "http://git.open-mesh.org/alfred.git";
  }

  file { '/etc/init.d/alfred':
    ensure => file,
    mode => "0755",
    source => "puppet:///modules/ffnord/etc/init.d/alfred";
  }

  file { '/usr/local/bin/alfred-announce':
    ensure => file,
    mode => "0755",
    source => "puppet:///modules/ffnord/usr/local/bin/alfred-announce";
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
    command => "/usr/bin/make CONFIG_ALFRED_CAPABILITIES=n",
    cwd => "/opt/alfred/",
    require => [Vcsrepo['/opt/alfred'],Package['build-essential'],Package['pkg-config'],Package['libgps-dev']];
  }

  service { 'alfred':
    ensure => running,
    hasrestart => true,
    enable => false,
    require => [Exec['alfred'],File['/etc/init.d/alfred']];
   }

  vcsrepo { '/opt/alfred-announce':
    ensure => present,
    provider => git,
    source => "https://github.com/ffnord/ffnord-alfred-announce.git",
    revision => "b31922fd53d2796b69ac4bd260ad837a200d0d5f",
    require => [Package['python3'],Package['ethtool']];
  }

  cron {
   'update-alfred-announce':
     command => 'PATH=/opt/alfred/:/bin:/usr/bin:/sbin:/usr/sbin/:$PATH /usr/local/bin/alfred-announce',
     user    => root,
     minute  => '*',
     require => [Vcsrepo['/opt/alfred-announce'], Vcsrepo['/opt/alfred'],File['/usr/local/bin/alfred-announce']];
  }
  
  ffnord::firewall::service { 'alfred':
    protos => ["udp"],
    chains => ["mesh","bat"],
    ports => ['16962'],
  }

  if $master {
    ffnord::resources::ffnord::field { "ALFRED_OPTS": value => '-m'; }
  } else {
    ffnord::resources::ffnord::field { "ALFRED_OPTS": value => ''; }
  }
}
