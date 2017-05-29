[![Build Status](https://travis-ci.org/ffnord/ffnord-puppet-gateway.svg?branch=master)](https://travis-ci.org/ffnord/ffnord-puppet-gateway)

# Freifunk Gateway Module

* Daniel Ehlers <danielehlers@mindeye.net>

This module tries to automate the configuration of a FFNord Freifunk Gateway.
The idea is to implement the step-by-step guide on http://wiki.freifunk.net/Freifunk_Hamburg/Gateway with multi community support and almost all other FFNord tools.

Basically this is a complete rewrite of the puppet scripts provided by the
Freifunk Hamburg Community.

The 'ffnord::mesh' block will setup a bridge, fastd, batman, ntp, dhcpd, dns (bind9),
radvd, bird6 and firewall rules vor IPv4 and IPv6.
There are types for setting up monitoring, icvpn, anonymous vpn and alfred announcements.

## Open Problems

* As usual, you should have configure the fully qualified domain name (fqdn) before running
  this module, you can check this with `hostname -f`.
* The configured dns server only provides support for the root zone.
  Custom tlds are currently not supported.  
* Bird6 must be reconfigured after a puppet run, otherwise the icvpn protocols are not available
* When touching the network devices on a rerun `named` should be restarted.

## TODO

* Bird IPv4 Route exchange
* Apply firewall rules automatially, when all rules are defined.

### Getting started

A detailed instruction and an example puppet manifest can be found at:  
https://github.com/ffnord/ffnord-puppet-gateway/blob/master/docs/admin/getting_started.rst

Now create your puppet manifest code and save it e.g. as `/root/gateway.pp`
