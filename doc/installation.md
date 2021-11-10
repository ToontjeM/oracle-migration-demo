# Installation

Docker, Vagrant, and VirtualBox needs to be installed on your computer to
prepare the demo with an Oracle instance and a virtual machine with all of the
EDB migration tools.  The following subsections details the setup for each
component.

## Docker

Docker needs to be installed onto your local system for creating an Oracle
instance.  The following steps are all done from the command line:

1. [Create a free account with
   Oracle](https://profile.oracle.com/myprofile/account/create-account.jspx).
2. Authenticate with Oracle's docker registry on the command line (only needs
   to be done once): `docker login container-registry.oracle.com`
3. The Oracle Express Edition docker image needs to be imported into Docker:
   `docker pull container-registry.oracle.com/database/express:latest`
4. Run the supplied script to create a custom Docker image for the demo:
   `docker/build-image`
5. Run the supplied script to create an Oracle instance in a container named
   `orademo` with: `docker/create-container`
6. Create the Oracle sample schemas and load data with supplied script:
   `docker/load-database`

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
2. vagrant --user=\<edb repo name\> --key=\<edb repo key\> up
