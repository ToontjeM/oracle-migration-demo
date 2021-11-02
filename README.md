# Oracle Migration Demo

This repository is a fork of the Oracle [Database Sample
Schemas](https://github.com/oracle/db-sample-schemas) with additional scripts
to demonstrate EDB migration tools.

# Installation

Docker, Vagrant, and VirtualBox needs to be installed on your computer to
prepare the demo with an Oracle instance and a virtual machine with all of the
EDB migration tools.  The following subsections details the setup for each
component.

## Docker

Docker needs to be installed onto your local system for creating an Oracle
instance.  The following steps are all done from the command line:

1. The Oracle Express Edition docker image needs to be imported into Docker:
   `docker pull container-registry.oracle.com/database/express:latest`
2. Run the supplied script to create a custom Docker image for the demo:
   `docker/build-image`
3. Run the supplied script to create an Oracle instance in a container named
   `orademo` with: `docker/create-container`
4. Create the Oracle sample schemas and load data with supplied script:
   `docker/load-database`

Once the Oracle instance is ready from running the `create-container`, the
following supplied script can be used to start a SQL\*Plus connection:
`docker/connect`

[Documentation specific to the Oracle Express Edition Docker
image](https://container-registry.oracle.com/ords/f?p=113:4:132631864087453:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:803,803,Oracle%20Database%20Express%20Edition,Oracle%20Database%20Express%20Edition,1,0&cs=3iKyi01vsM8dsWJWh9OTtPTryjUwRLNVIeihbeRvjRUPREsVO7EvBByNVjAnaY4bHb1MuuRmUCzojRxXq2b8QTQ).

## VirtualBox & Vagrant

[VirtualBox](https://www.virtualbox.org/wiki/Downloads) and
[Vagrant](https://www.vagrantup.com/downloads) need to be installed onto your
local system for creating a system that contains all of the EDB tools for
performing the migration from Oracle.

In preparation for building the virtual machine, an [EDB Web
site](https://www.enterprisedb.com/user/register?destination=/repository-access-request%3Fdestination%3Dnode/1255704%26resource%3D1255704%26ma_formid%3D2098)
account is needed in order to access the software respositores.  Note that the
**\<edb repo key\>** is ***not*** your password but the generated *Repository
Password* that can be found on [your account
page](https://www.enterprisedb.com/user/).

The virtual machine can now be built from the command line with the following
commands:

1. cd vagrant
2. vagrant --user=\<edb repo name\> --pass=\<edb repo key\> up

PEM is reachable at the following address
[https://10.10.10.10:8443/pem/](https://10.10.10.10:8443/pem/).
