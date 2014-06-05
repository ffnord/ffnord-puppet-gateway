# Freifunk Gateway Module

Martin Schütte <info@mschuette.name>
Daniel Ehlers <danielehlers@mindeye.net>

This module tries to automate the configuration of a FFNord Freifunk Gateway.
The idea is to implement the step-by-step guide on http://wiki.freifunk.net/Freifunk_Hamburg/Gateway with multi community support and almost all other FFNord tools.

Basically this is a complete rewrite of the puppet scripts provided by the
Freifunk Hamburg Community.

## Open Problems

* The apt repository at http://bird.network.cz/debian/ does not use PGP
  signatures, so `bird` and `bird6` will not be installed automatically.
* As usual, you should have configure the fully qualified domain name (fqdn) before running
  this module.
* Currently this module do not install a dns server, but reports one via 
  dhcp on every mesh bridge.

## Usage

Install as a puppet module, then include with node-specific parameters.

### Dependencies

Install Puppet and some required modules with:

```
apt-get install puppet git
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-apt
puppet module install puppetlabs-vcsrepo
puppet module install saz-sudo
puppet module install torrancew-account
```

Then add this module (which is not in the puppet forge, so it has to be
downloaded manually):

```
cd /etc/puppet/modules
git clone https://github.com/ffnord/ffnord-puppet-gateway
```

### Parameters

Now include the module in your manifest and provide all parameters.
Basically there are three kinds of parameters: user accounts (optional if you
do manual user management), network config (has to be in sync with the wiki
page), and credentials for fastd and openvpn.


Example puppet code (save e.g. as `/root/gateway.pp`):

```
# You can repeat this mesh block for every community you support
ffnord::mesh { 'mesh_ffeh':
      , mesh_name => "Freifunk Entenhausen"
      , mesh_code => "ffeh"
      , mesh_mac  => "de:ad:be:ef:de:ad"
      , mesh_prefix_ipv6 => "fda1:384a:74de:1::/64"
      , mesh_prefix_ipv4 => "255.255.255.128"
      , mesh_ipv6  => "fda1:384a:74de:1::1"
      , mesh_ipv4  => "10.13.37.1"

      , fastd_secret => "50292dd647f0e41eb0c72f18c652bfd1bea8c8bd00ae9da3f772068b78111644"
      , fastd_port   => 10000

      , dhcp_ranges => ['10.13.37.2 10.13.37.254','10.13.38.1 10.13.38.254']
      , dns_servers => ['10.13.39.1','10.13.41.1']
      }

class { 'ffnord::vpn': }

class { 'ffnord::monitor::munin':
      , host => '192.168.0.1'
}

class { 'ffnord::monitor::nrpe':
      , allowed_hosts => '217.70.197.95'
      }
```

### Run Puppet

To apply the puppet manifest (e.g. saved as `gw.pp`) run:

```
puppet apply --verbose /root/gateway.pp
```

The verbose flag is optional and shows all changes.
To be even more catious you can also add the `--noop` flag to only show changes
but not apply them.

