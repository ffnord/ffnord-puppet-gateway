Common Repository Handling
==========================

The ``ffnord-puppet-gateway`` module applicate some git repoistories
to retrieve metadata, peering pubkeys et cetera. Handling those repositories
boil down to pulling changes and regenerate configuration or reload services
on the change case. We have abstracted those mechanics to a template script
which is possitioned in ``/usr/local/include/ffnord-update.common``. 

::

  Usage: script-name [pull|reload|help]



