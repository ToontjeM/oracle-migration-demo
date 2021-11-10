# FOR EDB INTERNAL USE ONLY

# Oracle Migration Demo

This repository is a kit containing all of the information needed to perform a
demonstration migrating an Oracle Database to EDB Postgres Advanced Server
using EDB tools.

In preparation of performing the demo, the demonstrator needs to:

1. [Create an EDB account](https://www.enterprisedb.com/accounts/register) for
   logging into the EDB [Migration Portal](https://migration.enterprisedb.com)
   if you don't already have access.
2. Install software to provision systems for Oracle and EDB migration tools:
   [doc/installation.md](doc/installation.md)
   1. Build an Oracle instance with a database to migration,
   2. Build a virtual machine with all of the EDB migration tools.
3. Provision a BigAnimal cluster to be used as the migration destination.

A [demo guide](doc/guide.md) is provided as one method for performing a demo.

## Quick Notes

Once the migration kit is prepared:

* Connect to Oracle as *sysdba* on the command line: `docker/connect`

The installation scripts only need to be run once.  If you reboot your laptop,
you may need to restart the Docker containers:

* docker start orademo
* docker start edbdemo

# Contact Information

* Please [report any
  issues](https://github.com/EnterpriseDB/oracle-migration-demo/issues) online.
  (Requires a GitHub account that is a member of the EDB Organization.)
