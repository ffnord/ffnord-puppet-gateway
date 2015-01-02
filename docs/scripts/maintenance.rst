Maintenance Mode
================

A gateway is basically a production system throught which end-users build up
connections to the internet, to other parts of the intercity vpn or local
subnet. So before we can do hard maintenance, which probaliy require a reboot
or can lead to system failures, we have to be sure, that no end-user connections
are harmed, or at least minimize the number of harmed connections.

For this purpose the maintenance script will turn of ``radvd``, ``dhcpd`` and
prevent the host from announcing itself as gateway via batman-adv. After the 
DHCP-Lease time has passed all end-user devices should have merged to other
gateways in the network.

The maintenance mode is activated by:


.. code-block:: sh

  $ maintenance on

After activating will report it activation time with:


.. code-block:: sh

  $ maintenance status

After finishing the actuall maintenance you can revert the effect of the activation 
by turning the maintenance mode off.


.. code-block:: sh

  $ maintenance off
