class ffnord::icvpn (
  $router_id = $ffnord::params::router_id,
  $icvpn_as = $ffnord::params::icvpn_as,
) inherits ffnord::params {
  $tinc_name = $name

}

define ffnord::icvpn::setup (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ffnord::resources::meta

  ffnord::resources::ffnord::field {
    "ICVPN": value => '1';
    "ICVPN_EXCLUDE": value => "${icvpn_exclude_peerings}";
  }

  class { 'ffnord::tinc': 
    tinc_name    => $name,
    tinc_keyfile => $tinc_keyfile,

    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,

    icvpn_peers  => $icvpn_peerings;
  }

  ffnord::bird4::icvpn { $name:
    icvpn_as => $icvpn_as,
    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,
    tinc_keyfile => $tinc_keyfile }
  ffnord::bird6::icvpn { $name:
    icvpn_as => $icvpn_as,
    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,
    tinc_keyfile => $tinc_keyfile }
}
