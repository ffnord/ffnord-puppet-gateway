class ffnord::resources::bird {
  file {
   '/etc/bird/':
     ensure => directory,
     mode => '0755';
   '/etc/apt/preferences.d/bird':
     ensure => file,
     mode => "0644",
     owner => root,
     group => root,
     source => "puppet:///modules/ffnord/etc/apt/preferences.d/bird";
  }

  ffnord::firewall::service { "bird":
    ports  => ['179'],
    protos => ['tcp'],
    chains => ['mesh']
  }
}
