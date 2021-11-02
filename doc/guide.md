# Demo Guide

This is a recommended guide on how to perform a demonstrator of an Oracle
database migration using the EDB migration tools.

## EDB Migration Portal

The EDB Migration Portal is used to analyze the Oracle schema and generate a
compatible PostgreSQL Schema.

1. Verify the IP address of the Docker **orademo** instance, and the
   automatically generated password to the Oracle database in order to
   construct the command to connect to the Oracle database later in this guide.
   1. From a command line terminal, run: `docker logs orademo | head` and look
      for the password shown on the line `ORACLE PASSWORD FOR SYS AND SYSTEM:`.
      We will use `c90c1b7f2eb71d9c` for this guide.
   2. From a command line terminal, run: `docker container inspect orademo |
      grep IPAddress`.  We will use `172.17.0.2` for this guide.
2. Log into the EDB [Migration Portal](https://migration.enterprisedb.com).
3. Download the EDB DDL Extractor and save the file in the `vagrant/`
   subdirectory.  The `vagrant/` is a shared directory with the VM, where the
   DDL Extractor will be executed from.  A directory link to the DDL Extractor
   cannot be provided at this time.
4. Run the EDB DDL Extractor:  
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
5. Back in the Migration Portal, create a new project.
   1. Enter a new project name.
   2. The Oracle version used in this kit is 18c.
   3. The DDL file to choose was created in the last step and will be in the
      `vagrant/`.  The file name will resember something like
      `_gen_hr_ddls_YYMMDDHHMMSS.sql`
   4. Click **Create & assess**.
