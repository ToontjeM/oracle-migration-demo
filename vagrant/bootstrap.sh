#!/bin/sh

# Install the repository configuration
dnf -y install https://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm

# Visit https://www.enterprisedb.com/user to get your username and passkey
sed -i "s@<username>:<password>@${1}:${2}@" /etc/yum.repos.d/edb.repo

# Install EPEL repository
dnf -y install epel-release dnf-plugin-config-manager

# Disable the built-in PostgreSQL module:
dnf -qy module disable postgresql

# Install selected packages
dnf -y install edb-migrationtoolkit edb-as13-edbplus edb-as13-server edb-pem \
		ppas-xdb

/usr/edb/as13/bin/edb-as-13-setup initdb
# Open up the database to the whole world, because it's easy to script it this
# way.
cat << EOF > /var/lib/edb/as13/data/pg_hba.conf
local   all             all                                  trust
host    all             all             0.0.0.0/0            trust
host    all             all             ::/0                 trust
local   replication     all                                  trust
host    replication     all             0.0.0.0/0            trust
host    replication     all             ::/0                 trust
EOF
systemctl start edb-as-13

# Configure PEM
/usr/edb/pem/bin/configure-pem-server.sh \
		--pemagent-certificate-path ~/.pem/ \
		--db-install-path /usr/edb/as13 \
		--cidr-address 0.0.0.0/0 \
		--db-unitfile edb-as-13 \
		--port 5444 \
		--superuser enterprisedb \
		--superpassword enterprisedb \
		--type 1

echo "You can now connect to PEM at https://127.0.0.1:8443/pem"

# LiveCompare
curl https://techsupport.enterprisedb.com/api/repository/QGcOzwnsVlaKF5jQfYlIwq57kUbKVtAM/products/livecompare/release/13/rpm/volatile | bash

# TODO: Consider using Oracle Linux and thus having the Oracle repositories
# readily available.
# Oracle client packages:
dnf -y install https://download.oracle.com/otn_software/linux/instantclient/213000/oracle-instantclient-basic-21.3.0.0.0-1.el8.x86_64.rpm
dnf -y install https://download.oracle.com/otn_software/linux/instantclient/213000/oracle-instantclient-sqlplus-21.3.0.0.0-1.el8.x86_64.rpm
