class ffnord::resources::fastd {

  include ffnord::resources::apt-tools 
  include ffnord::resources::repo-universe-factory

  Class[ffnord::resources::repo-universe-factory]
  -> Exec['apt-get update']
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

# TODO Enforce Exec['apt-get update'] before target is interpreted as finished
class ffnord::resources::repo-universe-factory {
  ffnord::resources::apt-source { "repo.universe-factory.net": repo => "deb http://repo.universe-factory.net/debian/ sid main", key => "16EF3F64CB201D9C"} 
}

class ffnord::resources::apt-tools  {
  exec { "apt-get update":
    command => "/usr/bin/apt-get update",
    onlyif => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'";
  }
}

define ffnord::resources::apt-source ($repo,$key){
  exec { "gpg recv": command => "/usr/bin/gpg --keyserver pgpkeys.mit.edu --recv-key ${key}"; } 
  -> exec { "apt-key": command => "/usr/bin/gpg -a --export ${key} | /usr/bin/apt-key add -"; }
  -> file { '/etc/apt/sources.list.d/90-repo.universe-factory.net.list': ensure => file, content => inline_template($repo);}

}
