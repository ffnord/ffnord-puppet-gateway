class ffnord::resources::batman-adv (
  $batman_version = $ffnord::params::batman_version
) inherits ffnord::params {
  include ffnord::resources::repos

  Class[ffnord::resources::repos]
  ->
  package {
    'batctl': ensure => installed;
    'batman-adv-dkms': ensure => $batman_version ? {
      14 => 'installed',
      default => 'purged'
    }
  }
}
