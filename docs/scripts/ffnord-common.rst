Common Repository Handling
==========================

The ``ffnord-puppet-gateway`` module applicates some git repositories
to retrieve metadata, peering pubkeys et cetera. Handling those repositories
boil down to pulling changes and regenerate configuration or reload services
in case something changed. We have abstracted those mechanics into a template 
script placed in ``/usr/local/include/ffnord-update.common``. 

::

  Usage: /usr/local/include/ffnord-update.common [pull|reload|help]



