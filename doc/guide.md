# Demo Guide

This is a recommended guide on how to perform a demonstrator of an Oracle
database migration using the EDB migration tools.

## EDB Migration Portal

The EDB Migration Portal is used to analyze the Oracle schema and generate a
compatible PostgreSQL Schema.

### Preparation

Passwords, IP addresses and connection information should be gathered from the
Oracle Docker container and the BigAnimal cluster before performing this part
of the demo.

The IP address and Oracle sysdba password needs to be collected from the Oracle
container:

1. From a command line terminal, run: `docker logs orademo | head` and look for
   the password shown on the line `ORACLE PASSWORD FOR SYS AND SYSTEM:`.  We
   will use `c90c1b7f2eb71d9c` for this guide.
2. From a command line terminal, run: `docker container inspect orademo | grep
   IPAddress`.  We will use `172.17.0.2` for this guide.

The connection information from the BigAnimal clusters:

1. Click on `Clusters` in the left sidebar.
2. Click on the lock shaped icon next to the cluster to use.
3. Note the `Dbname`, `Host`, and `User` information.  The password will be
   what was entered when creating the cluster.

### Demonstration

1. Log into the EDB [Migration Portal](https://migration.enterprisedb.com).
2. Download the EDB DDL Extractor and save the file in the `vagrant/`
   subdirectory.  The `vagrant/` is a shared directory with the VM, where the
   DDL Extractor will be executed from.  A directory link to the DDL Extractor
   cannot be provided at this time.
3. Run the EDB DDL Extractor:  
   1. Open a command line terminal, starting at the top of the
      *oracle-migration-demo* directory.
   2. Connect to the **edbdemo** virtual machine:  
      `cd vagrant`  
      `vagrant ssh`
   3. Execute the EDB DDL Extractor script, using the IP Address and Oracle
      database password extracted at the top of this section:  
      `cd vagrant`  
      `[vagrant@localhost ~]$ cd /vagrant`  
      `[vagrant@localhost ~]$ sqlplus sys/c90c1b7f2eb71d9c@//172.17.0.2:1521/XEPDB1 as sysdba`  
      `SQL> @edb_ddl_extractor.sql`
   4. Press `RETURN` at the first prompt to continue:  
      `Press RETURN to continue ...`  
   5. Enter `HR` to only extract the `HR` database (multiple databases are
      installed:  
      `Enter a comma-separated list of schemas, max up to 240 characters
      (Default all schemas): HR`  
   6. Press `RETURN` at next prompt to use the current location:  
      `Location for output file (Default current location) : `  
   7. Enter `yes` at next prompt to extract any objects from other schemas:  
      `Extract dependent object from other schemas?(yes/no) (Default no /
      Ignored for all schemas option):yes`  
4. Back in the Migration Portal, create a new project.
   1. Enter a new project name.
   2. The Oracle version used in this kit is 18c.
   3. The DDL file to choose was created in the last step and will be in the
      `vagrant/`.  The file name will resember something like
      `_gen_hr_ddls_YYMMDDHHMMSS.sql`
   4. Click **Create & assess**.
5. Demonstrate how to correct the reported errors.
   1. TBD
6. Create the target database on BigAnimal.
7. Migrate the schema to BigAnimal.
   1. Click on `Migrate to ...`
   2. Select `EDB Postgres Advanced Server on Cloud` and click `Next`.
   3. The `HR` should be selected, and the only schema listed.  Click `Next`.
   4. Select `BigAnimal` and click `Next`.
   5. Click `Next`.
   6. Enter the connection information to BigAnimal, click `Test Connection`,
      then click `Next`.
      1. Target Database: edb_admin
      2. Host Name/Address: copied from above
      3. Password: password that was entered when creating BigAnimal cluster
   7. Migration is complete, you may click `Done`.

## Migration Took Kit

The previously used IP Address and the Oracle user password of the Oracle
docker instance is to be reused here, as well as the connection information for
the BigAnimal cluster that was previously created.

1. Edit the MTK properties file with by running the follow script (the script
   opens the properties file in an editor on the virtual machine):
   `docker/config-mtk`
   1. Update `SRC_DB_URL`: jdbc:oracle:thin:@//172.17.0.2:1521/XEPDB1
   2. Update `SRC_DB_USER`: system
   3. Update `SRC_DB_PASSWORD`: c90c1b7f2eb71d9c
   4. Update `TARGET_DB_URL`: jdbc:edb://p-c659g7jh5vfavr7tfs60.qsbilba3hlgp1vqr.biganimal.io:5432/edb_admin
   5. Update `TARGET_DB_USER`: edb_admin
   6. Update `TARGET_DB_PASSWORD`:
3. Run MTK to migrate the data from the Oracle database to BigAnimal:
   `docker/mtk-migrate` 
