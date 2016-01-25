class ffnord::resources::bird (
  $include_bird4 = $ffnord::params::include_bird4,
  $include_bird6 = $ffnord::params::include_bird6,
) inherits ffnord::params {
  file {
    '/etc/bird/':
      ensure => directory,
      mode => '0755';
  }
  if($lsbdistcodename=="wheezy"){
    file {
     '/etc/apt/preferences.d/bird':
        ensure => file,
        mode => "0644",
        owner => root,
        group => root,
        source => "puppet:///modules/ffnord/etc/apt/preferences.d/bird";
    }
  }

  ffnord::firewall::service { "bird":
    ports  => ['179'],
    protos => ['tcp'],
    chains => ['mesh']
  }

  ffnord::resources::ffnord::field {
    "INCLUDE_BIRD4": value => $include_bird4;
    "INCLUDE_BIRD6": value => $include_bird6;
  }

}
