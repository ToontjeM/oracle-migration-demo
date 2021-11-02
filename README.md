# Oracle Migration Demo

This repository is a kit containing all of the information needed to perform a
demonstration migrating an Oracle Database to EDB Postgres Advanced Server
using EDB tools.

In preparation of performing the demo, the demonstrator needs to:

1. [Create an EDB account](https://www.enterprisedb.com/accounts/register) for
   logging into the EDB [Migration Portal](https://migration.enterprisedb.com)
   if you don't already have access.
2. Set up an Oracle instance with a database to migration,
   [doc/installation.md](doc/installation.md)
3. Set up a virtual machine with all of the EDB migration tools.
4. Provision a BigAnimal cluster to be used as the migration destination.

Quick notes once the migration kit is prepared:

* Connect to Oracle as sysdba on the command line: `docker/connect`
* PEM is reachable at the following local address:
  [https://10.10.10.10:8443/pem/](https://10.10.10.10:8443/pem/).

[Demo guide](doc/guide.md).
