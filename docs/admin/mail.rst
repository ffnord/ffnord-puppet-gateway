Mail Notification
=================

It is nice to know what is going on. Most cases of that problem can be handled
with a monitoring system like ``icinga`` or ``nagios``, but some unique events
need special notifications.

So basically every script executed via cron is designed to have no output in the
success case, but produce some informations, when an important task is done
and of course in the error case.

Crontab
-------

.. code-block:: shell

  # crontab -e

And insert the following line on top of the cronjobs

::

  MAILTO=address-of-your-noc-team@your.domain


NullMailer
----------

::

  # aptitude install nullmailer
