class ffnord::nullmailer(
  $adminaddr,
  $defaultdomain,
  $remotes,
) {

  package {
    'nullmailer':
      ensure => installed;
  }

  file {
    '/etc/nullmailer/adminaddr':
      ensure => file,
      content => $adminaddr,
      require => Package[nullmailer];
    '/etc/nullmailer/defaultdomain':
      ensure => file,
      content => $defaultdomain,
      require => Package[nullmailer];
    '/etc/nullmailer/remotes':
      ensure => file,
      content => $remotes,
      require => Package[nullmailer];
  } ->

  service {
    'nullmailer':
      ensure => running,
      enable => true,
      hasrestart => true,
      require => [
        Package['nullmailer']
      ];
  }
}
