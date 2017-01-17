class ffnord::resources::fastd {

  include ffnord::resources::repos

  Class[ffnord::resources::repos]
  -> package { 'ffnord::resources::fastd': ensure => installed, name => 'fastd';}
  -> service { 'ffnord::resources::fastd': ensure => running, name => 'fastd', hasrestart => true, enable => true; }

  file {
    '/usr/local/bin/fastd-query':
      ensure => file,
      mode => '0755',
      require => [
        Package['jq'],
        Package['socat'],
      ],
      source => 'puppet:///modules/ffnord/usr/local/bin/fastd-query';
  }

  package { ['jq','socat']:
    ensure => installed,
    require => Class[ffnord::resources::repos];
  }
}

class ffnord::resources::fastd::auto_fetch_keys {

  include ffnord::resources::update

  file { '/usr/local/bin/update-fastd-keys':
    ensure => file,
    mode => '0755',
    source => 'puppet:///modules/ffnord/usr/local/bin/update-fastd-keys',
    require => Class['ffnord::resources::update'];
  }

  file { '/usr/local/bin/autoupdate_fastd_keys': ensure => absent; }

  package { 'ffnord::resources::cron': ensure => installed, name => 'cron'; }
  -> cron {
  'autoupdate_fastd':
    command => '/usr/local/bin/update-fastd-keys pull',
    user    => root,
    minute  => '*/5';
  }
}
