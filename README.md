# Monitoring Plugins for AIX

This repository contains monitoring plugins for AIX. They are designed
for Icinga, and will work for Nagios, Naemon, Shinken, Sensu and other
monitoring systems using the same interface for check plugins.

They are written using the [Monitoring Plugins Development
Guidelines](https://www.monitoring-plugins.org/doc/guidelines.html)

Goals for these plugins are:

* Should work on old AIX servers. They are written for perl 5.8.
* Should not use modules outside the perl distribution.
* Should work out of the box as a single file download.
* Should be self-documented, using --help and --man options.
* Should behave roughly the same.

The plugins are all MIT licensed.
