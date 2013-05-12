Description
===========

Installs the qpscanner.

Attributes
==========

* `node['qpscanner']['install_path']` (Default is /vagrant/wwwroot)
* `node['qpscanner']['owner']` (Default is `nil` which will result in owner being set to `node['cf10']['installer']['runtimeuser']`)
* `node['qpscanner']['group']` (Default is bin)
* `node['qpscanner']['download']['url']` (Default is https://github.com/boughtonp/qpscanner/archive/master.zip)
* `node['qpscanner']['create_apache_alias']` (Default is false)

Usage
=====

On ColdFusion server nodes:

    include_recipe "qpscanner"