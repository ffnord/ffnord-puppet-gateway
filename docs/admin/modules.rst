Puppet Classes and Types
========================

The ffnord-puppet-gateway module provide several puppet resources, in here
we will discuss all directly usable resources. The omitted one are discussed
in the developer documentation.

ffnord::params (class)
----------------------


Attributes
``````````
.. code-block:: ruby

  class { 'ffnord::params ':
    router_id      => # The id of this router, probably the mesh ipv4 address of the mesh device of the providing community.
    icvpn_as       => # The Autonomous-System-Number of the providing community.
    wan_devices    => # Array of wan device names of the host.
    debian_mirror  => # Default Debian mirror, default to ``http://ftp.de.debian.org/debian/``.
    include_bird4  => # Include support for bird service, defaults to ``True``.
    include_bird6  => # Incldue support for bird6 service, defaults to ``True``.
    maintenance    => # Default value for maintenance mode, timestamp.
  }

router_id
.........
* Example value: ``10.35.0.1``

icvpn_as
........
* Example value: ``65034``

This should be ASN of the providing community. The value is currently used for icvpn only,
for local peerings or iBGP the ASN given in the ``ffnord::mesh`` resource is used.

wan_devices
...........
* Example value: ``['eth0']``

List of WAN devices on the target host. These devices will be in the WAN firewall zone.

debian_mirror
.............
* Default: ``http://ftp.de.debian.org/debian/``

include_bird4
.............
* Default: ``true``

Shall the IPv4 version of the bird service be deployed.

include_bird6
.............
* Default: ``true``

Shall the IPv6 version of the bird service be deployed.

maintenance
...........
* Default: ``0``

You can define a value greater than zero to this attribute to bring the host into maintenance
mode after puppet run, the value is currently not checked by any manifests in this module.
So all services will be started after a puppet run, but the maintenance mode critical
will son after shutdown by the ``check-gateway`` script.

ffnord::mesh (type)
-------------------

This type introduces a new community to the host, there should be at least one ``ffnord::mesh`` resource in your manifest. Furthermore there have to be one declaration which match the values of the ``ffnord::param`` class.

Currently this makes the host to be a gateway for the introduced community.
Introducing ``ntpd``, ``dhcpd``, ``firewall``, ``bird``, ``bird6``, ``bind9`` and ``fastd`` services and configurating the network interfaces ``br-${mesh_code}``.

.. code-block:: ruby

  ffnord::mesh { 'resource_name':
    mesh_name       => # Name of this community, will be passed to some comments in some configuration files.
    mesh_code       => # Code of this community, e.g.: ``ffgc``
    mesh_as         => # ASN of this community.
    mesh_mac        => # The MAC Address of this host in the mesh network of this community.
    mesh_ipv6       => # The IPv6 Address of this host in the mesh network of this community.
    mesh_ipv4       => # The IPv4 Address of this host in the mesh network of this community.

    mesh_mtu        => # The mtu used for the mesh interface of this community.
    range_ipv4      => # The IPv4 subnet used by this community.
    mesh_peerings   => # Path to the local peerings description yaml file.
    fastd_secret    => # Path to a fastd configuration snipet which contains the secret for this communities host.
    fastd_port      => # Port used for the fastd instance for this community.
    fastd_peers_git => # The URL to the git repository used to store fastd public keys in this community.
    dhcp_ranges     => # Array of ranges used for distribution via dhcp, in the form '10.35.4.2 10.35.4.254'.
    dns_servers     => # Array of IPv4 addresses of DNS servers.
  }

Attributes
``````````

mesh_name
.........
* Example value: ``Freifunk Gotham City``

mesh_code
.........
* Example value: ``ffgc``

mesh_as
.......
* Example value: ``65035``

mesh_mac
........
* Example value: ``'de:ad:be:ef:de:ad'``

mesh_ipv6
.........
* Example value: ``'fd35:f308:a922::ff00/64'``

mesh_ipv4
.........
* Example value: ``'10.35.0.1/19'``

mesh_mtu
........
* Default: ``1426``

The mtu used for the fastd instance of this communities mesh interface.

range_ipv4
..........
* Example value: ``'10.35.0.0/16'``

mesh_peerings
.............
* Example value: ``'/root/mesh_peerings.yaml'``

fastd_secret
............
* Example value: ``'/root/fastd_secret.key'``

fastd_port
..........
* Example value: ``10035``

fastd_peers_git
...............
* Example value: ``'git://somehost/peers.git'``

dhcp_ranges
...........
* Default: ``[]``

dns_servers
...........
* Default: ``[]``

ffnord::named::zone (type)
--------------------------
When you have a zone that is managed by your community you can import the
corresponding zone files from a git repository and include it into the local
running name server. The repo and configuration file in it must forfill some
requirements:

* There must be an configuration file named ``${resource_name}.conf``
* All files which are included in the configuratoin file should used a absoulte
  path beginning with ``/etc/bind/zones/${resource_name}/``.

.. code-block:: ruby

  ffnord::named::zone { 'resource_name':
    zone_git     => # Path to a git repository
    exclude_meta => # Optionally exclude zones from icvpn-meta
  }

Attributes
``````````

zone_git
........
* Example value: ``git://somehost/zone.git``

exclude_meta
............
* Default: ``''``

ffnord::dhcpd::static (type)
----------------------------

ffnord::vpn::provider::generic (class)
--------------------------------------

ffnord::vpn::provider::hideio (class)
-------------------------------------
This class contains the authentification data for the vpn-tunnel, which is 
used to tunnel the all of the networks traffic into the internet.

.. code-block:: ruby

  class {
    'ffnord::vpn::provider::hideio':
      openvpn_server => # a url or ip-address to an hideio-server
      openvpn_port   => # Port of the hideio-server
      openvpn_user   => # Username used to authentificate at the server
      openvpn_password => # Password used to authentificate at the server
  }

Attributes
``````````

openvpn_server
..............
The server you want the openvpn connect to.
* Example value: ``"nl-7.hide.io"``

openvpn_port
............
The port the server you connect to uses for openvpn.
* Example value: ``3478``

openvpn_user
............
The username to authentificate at the openvpn-server.
* Example value: ``"wayne"``

openvpn_password
................
The password to authentificate at the openvpn-server.
* Example value: ``"brucessecretpw"``


ffnord::icvpn::setup (type)
---------------------------
This type contains all information, which is used to connect to the icvpn
and establish BGP-peerings with other communitys.

.. code-block:: ruby

  ffnord :: icvpn::setup {
    icvpn_as               => # AS of the community peering
    icvpn_ipv4_address     => # transfer network IPv4 address
    icvpn_ipv6_address     => # transfer network IPv6 address
    icvpn_exclude_peerings => # Lists of icvpn names
  
    tinc_keyfile => # Private Key for tinc
  }

Attributes
``````````

icvpn_as
........
The ASN of your Community, must be the same as ``mesh_as`` in ``ffnord::mesh``.
* Example value: ``65035``

icvpn_ipv4_address
..................
* Example value: ``"10.112.0.1"``

icvpn_ipv6_address
..................
* Example value: ``"fec0::a:cf:0:35",``

icvpn_exclude_peerings
......................
* Example value: ``[gotham]``

tinc_keyfile
............
* Example value: ``"/root/tinc_rsa_key.priv"``


ffnord::monitor::munin (class)
------------------------------

ffnord::alfred (class)
----------------------

ffnord::etckeeper (class)
-------------------------

