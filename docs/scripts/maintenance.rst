Maintenance Mode
================

A gateway is basically a production system throughout which end-users build up
connections to the internet, to other parts of the intercity vpn or to a local
subnet. So before we can do hard maintenance, which probabliy require a reboot
or can lead to system failures, we have to be sure that no end-user connections
are harmed, or at least minimize the number of harmed connections.

For this purpose the maintenance script will turn of ``radvd``, ``dhcpd`` and
prevent the host from announcing itself as gateway via batman-adv an longer.
After the DHCP-Lease time has expired all end-user devices should have merged
onto other gateways in the network.

The maintenance mode is activated by:


.. code-block:: sh

  $ maintenance on

When already activated this will report the status and elapsed time since the activation:


.. code-block:: sh

  $ maintenance status

After finishing the actual maintenance you can revert the effect of the activation 
by turning the maintenance mode off with:


.. code-block:: sh

  $ maintenance off
