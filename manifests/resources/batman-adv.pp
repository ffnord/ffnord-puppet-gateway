class ffnord::resources::batman-adv {
  
  include ffnord::resources::apt-tools 
  include ffnord::resources::repo-universe-factory

  Class[ffnord::resources::repo-universe-factory]
  -> Exec['apt-get update']
  -> package{ 'batctl': ensure => installed;
           'batman-adv-dkms': ensure => installed;
         }
}
