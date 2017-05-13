class ffnord::params (
  $router_id,     # This hosts router identifier, e.g. 10.35.0.1
  $icvpn_as,      # Main AS number of this host, e.g. 65035
                  # This number will be used for the main bird configuration
  $wan_devices,   # Network devices which are in the wan zone
  $debian_mirror = 'http://ftp.de.debian.org/debian/',
  $include_bird4 = true, # support bird
  $include_bird6 = true, # support bird6

  # Settings for connection tracking, udp and tcp timeouts
  $conntrack_max = 32768,
  $conntrack_tcp_timeout = 1200,
  $conntrack_udp_timeout = 65,

  # Send/Recv socket memory, should be adjusted depending on uplink nic
  $wmem_default = 87380,
  $wmem_max     = 12582912,
  $rmem_default = 87380,
  $rmem_max     = 12582912,

  # Max Backlog 
  $max_backlog  = 5000,

  # Gateway check addresses, whitespace seperated string
  $gw_control_ips = '138.201.16.163',

  # Default values for ffnord config
  $maintenance = 0, # Shall the maintenance mode be active after installation?

  # B.A.T.M.A.N. adv version
  $batman_version = 14,
) {
}
