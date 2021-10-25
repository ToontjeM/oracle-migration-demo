# Oracle Migration Demo

This repository contains the [Oracle Database Sample
Schemas](https://github.com/oracle/db-sample-schemas) and additional scripts to
help one demonstrate EDB migration tools.

# Installation

## Docker

Docker needs to be installed onto your local system for creating an Oracle
instance.  The following steps are all done from the command line:

1. The Oracle Express Edition docker image needs to be imported into Docker:
   `docker pull container-registry.oracle.com/database/express:latest`
2. Run the supplied script to create a custom Docker image for the demo:
   `docker/build-image`
3. Run the supplied script to create an Oracle instance in a container named
   `orademo` with: `docker/create-container`
4. Monitor the Oracle instance create by running the docker command `docker
   logs -f orademo` until the message `DATABASE IS READY TO USE!` is emitted.
5. Create the Oracle sample schemas, which also loads data by running the
   supplied script: `docker/load-database`

Once the Oracle instance is ready from running the `create-container`, the
following supplied script can be used to start a SQL\*Plus connection:
`docker/connect`

[Documentation specific to the Oracle Express Edition Docker
image](https://container-registry.oracle.com/ords/f?p=113:4:132631864087453:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:803,803,Oracle%20Database%20Express%20Edition,Oracle%20Database%20Express%20Edition,1,0&cs=3iKyi01vsM8dsWJWh9OTtPTryjUwRLNVIeihbeRvjRUPREsVO7EvBByNVjAnaY4bHb1MuuRmUCzojRxXq2b8QTQ).
