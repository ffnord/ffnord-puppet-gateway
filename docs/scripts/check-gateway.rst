check-gateway
=============

This script checks the vpn uplink status of the host and takes action depending
on the result involving the maintenance state. By default this script is executed
every minute.

The check is processed by pinging through the uplink interface. The interface
is defined by ``GW_VPN_INTERFACE`` in the ``/etc/ffnord`` configuration file.
The target is defined by ``GW_CONTROL_IP`` in the same file.

When the uplink is working and maintenance is off then

* make sure DHCP Daemon is running and
* activating the gateway feature of batman-adv.

If maintenance mode is activated or the uplink is not working

* shutdown DHCP Daemon and
* deactivate the gateway feaure of batman-adv.

When uplink is not working, we want clients to migrate to another host,
so shutting down DHCP service prevents them to extend their lease.

