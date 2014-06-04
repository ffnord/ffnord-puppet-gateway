class ffnord::resources::batman-adv () {
  include ffnord::resources::repos

  Class[ffnord::resources::repos]
  -> 
  package { 
    'vim': ensure => installed; 
    'batctl': ensure => installed;
    'batman-adv-dkms': ensure => installed;
  }
}
