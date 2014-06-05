class ffnord::resources::fastd {

  include ffnord::resources::repos

  Class[ffnord::resources::repos]
  -> package { 'ffnord::resources::fastd': name => "fastd", ensure => installed;}
  -> service { 'ffnord::resources::fastd': name => "fastd", ensure => running, enable => true; }

}

class ffnord::resources::fastd::auto_fetch_keys {
  file { '/usr/local/bin/autoupdate_fastd_keys':
    ensure => file,
    source => 'puppet:///modules/ffnord/usr/local/bin/autoupdate_fastd_keys';
  }
  package { 'ffnord::resources::cron': name => "cron", ensure => installed; }
  -> cron {
   'autoupdate_fastd':
     command => '/usr/local/bin/autoupdate_fastd_keys',
     user    => root,
     minute  => '*/5';
  }
}
