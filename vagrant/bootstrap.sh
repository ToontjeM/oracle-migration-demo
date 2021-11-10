#!/bin/sh

set -x

# Install the repository configuration
dnf -y install \
		https://${1}:${2}@yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm

# Visit https://www.enterprisedb.com/user to get your username and passkey
sed -i "s@<username>:<password>@${1}:${2}@" /etc/yum.repos.d/edb.repo

# Install EPEL repository
dnf -y install oracle-epel-release-el8 dnf-plugin-config-manager || exit 1

# Disable the built-in PostgreSQL module:
dnf -qy module disable postgresql || exit 1

# Install selected packages
dnf -y install edb-migrationtoolkit edb-as13-edbplus edb-as13-server edb-pem \
		ppas-xdb || exit 1

# Try to install everyone's favorite text editor because we don't know who will
# want to use what...
dnf -y install emacs-nox nano vim || exit 1

/usr/edb/as13/bin/edb-as-13-setup initdb || exit 1
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
systemctl enable edb-as-13
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
		--type 1 \
		|| exit 1

systemctl enable httpd

# LiveCompare
curl https://techsupport.enterprisedb.com/api/repository/QGcOzwnsVlaKF5jQfYlIwq57kUbKVtAM/products/livecompare/release/13/rpm/volatile | bash

# Oracle client packages:
dnf -y install oracle-instantclient-release-el8 || exit 1
dnf -y install oracle-instantclient-jdbc oracle-instantclient-odbc \
		oracle-instantclient-sqlplus || exit 1

# Oracle JDBC driver:
OJDBC="ojdbc8-full"
curl -OL https://download.oracle.com/otn-pub/otn_software/jdbc/1815/${OJDBC}.tar.gz
tar xvf ${OJDBC}.tar.gz || exit 1
(cd ${OJDBC} && mv *.jar /usr/edb/migrationtoolkit/lib) || exit 1
