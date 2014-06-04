class ffnord::resources::fastd {

  include ffnord::resources::repos

  Class[ffnord::resources::repos]
  -> package { 'ffnord::resources::fastd': name => "fastd", ensure => installed;}
  -> service { 'ffnord::resources::fastd': name => "fastd", ensure => running, enable => true; }

}

class ffnord::resources::fastd::auto_fetch_keys {
  file { '/sbin/autoupdate_fastd_keys.sh':
    ensure => file,
    source => 'puppet:///modules/ffnord/root/bin/autoupdate_fastd_keys.sh';
  }
  package { 'ffnord::resources::cron': name => "cron", ensure => installed; }
  -> cron {
   'autoupdate_fastd':
     command => '/root/bin/autoupdate_fastd_keys.sh',
     user    => root,
     minute  => '*/5';
  }
}
