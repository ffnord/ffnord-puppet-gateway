class ffnord::resources::batman-adv () {
  include ffnord::resources::repos

  Class[ffnord::resources::repos]
  ->
  package {
    'batctl': ensure => installed;
    'batman-adv-dkms': ensure => installed;
  }
}
