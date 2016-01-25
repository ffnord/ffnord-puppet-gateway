class ffnord::mosh {

  require ffnord::resources::repos
  if($lsbdistcodename=="wheezy"){
    package {
      'mosh':
        ensure => installed,
        require => [
          File['/etc/apt/preferences.d/mosh'],
          Apt::Source['debian-backports']
        ];
    }

    file {
     '/etc/apt/preferences.d/mosh':
       ensure => file,
       mode => "0644",
       owner => root,
       group => root,
       source => "puppet:///modules/ffnord/etc/apt/preferences.d/mosh";
    }
  } else {
    package {
      'mosh':
        ensure => installed;
    }
  }
  ffnord::firewall::service { "mosh":
    protos => ['udp'],
    ports  => ['60000-61000'],
    chains => ['wan']
  }
}
