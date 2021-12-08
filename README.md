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

### Starting Docker Containers

The installation scripts only need to be run once.  If you reboot your laptop,
you may need to restart the Docker containers:

* `docker start orademo`
* `docker start edbdemo`
* `docker/start-pem` - The **edbdemo** container needs to be started first,
  then this script starts **httpd** and PostgreSQL processes.

### Connect to Oracle Database

Once the containers have been created and are running, you can connect to
Oracle as *sysdba* by running the following helper script: `docker/connect`

```
% docker/connect
executing: sqlplus sys/c90c1b7f2eb71d9c@XEPDB1 as sysdba

SQL*Plus: Release 18.0.0.0.0 - Production on Wed Dec 8 18:04:28 2021
Version 18.4.0.0.0

Copyright (c) 1982, 2018, Oracle.  All rights reserved.


Connected to:
Oracle Database 18c Express Edition Release 18.0.0.0.0 - Production
Version 18.4.0.0.0

SQL>
```

### Container information

Run the following script to get a summary of each container's IP address,
automatically generated Oracle database passwords, and other helpful URLs:
`docker/info`

```
% docker/info
EDB IP Address: 172.17.0.3
EDB PEM URL: https://172.17.0.3/pem
Oracle Database Password: c90c1b7f2eb71d9c
Oracle Database IP Address: 172.17.0.2
```

# Contact Information

* Please [report any
  issues](https://github.com/EnterpriseDB/oracle-migration-demo/issues) online.
  (Requires a GitHub account that is a member of the EDB Organization.)
