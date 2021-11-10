# Installation

Docker needs to be installed on your computer to prepare the demo with an
Oracle instance and a virtual machine with all of the EDB migration tools.  The
following steps are all done from the command line:

1. [Create a free account with
   Oracle](https://profile.oracle.com/myprofile/account/create-account.jspx).
2. Authenticate with Oracle's docker registry on the command line (only needs
   to be done once): `docker login container-registry.oracle.com`
3. Pull the Docker images to use:
   1. Oracle Express Edition:
      `docker pull container-registry.oracle.com/database/express:latest`
   2. Oracle Linux 7:
      `docker pull oraclelinux:7`
4. Run the supplied script to build the Docker images for the demo:
   `docker/build-image \<edb repo name\> \<edb repo key\>`
5. Run the supplied script to create the Docker containers for the demo:
   `docker/create-container`
6. Create the Oracle sample schemas and load data with supplied script:
   `docker/load-database`
