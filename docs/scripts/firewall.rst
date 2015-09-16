Firewall configuration (build_firewall)
=======================================

The firewall is configured by a set of scripts located in ``/etc/iptables.d/``
which use some macro functions which are defined in the ``build-firewall`` script.

The scripts are prefixed with three didgets and are processed in ascending numerical order.
Ranges of didgets are used for special purposes.

Macros
------

ip4tables, ip6tables and ip46tables
```````````````````````````````````

block4 and block6
`````````````````

ratelimit4, ratelimit6 and ratelimit46
``````````````````````````````````````

Default Chains
--------------

Zone Chains
```````````

zone-FORWARD
............

zone-INPUT
..........

Debug Chains
````````````

DROP-log
........


Rebuild Firewall Rules
----------------------

.. code-block:: sh

  $ build-firewall
