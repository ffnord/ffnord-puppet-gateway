class ffnord::params (
  $router_id, # This hosts router identifier, e.g. 10.35.0.1
  $icvpn_as,  # Main AS number of this host, e.g. 65035
              # This number will be used for the main bird configuration
  $wan_devices, # Network devices which are in the wan zone
  $debian_mirror = 'http://ftp.de.debian.org/debian/',

  # Default values for ffnord config
  $maintenance = 0, # Shall the maintenance mode be active after installation
) {
}
