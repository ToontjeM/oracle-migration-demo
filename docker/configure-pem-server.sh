#!/bin/bash
#***************************************************************************
#
# Postgres Enterprise Manager
#
# Copyright (C) 2016 - 2021, EnterpriseDB Corporation. All rights reserved.
#
#***************************************************************************


# ---------------------
# Switch variables
# ---------------------

AGENT_SERVICE_NAME_PROVIDED=0
PG_INSTALLPATH_PROVIDED=0
AGENT_INSTALLPATH_PROVIDED=0
UNINSTALL_PEM_SERVER_PROVIDED=0
DATADIR_PROVIDED=0
DB_SUPERUSER_PROVIDED=0
DB_PGHOST_PROVIDED=0
DB_PGPORT_PROVIDED=0
DB_SUPER_PASSWORD_PROVIDED=0
CIDR_ADDR_PROVIDED=0
DB_UNIT_FILE_PROVIDED=0
PEM_BASE_DIR=/usr/edb/pem
PEM_BRANDING_EDB_WL=edb
PEM_BRANDING_EDB_CAPS_WL=EDB
PEM_BRANDING_COMPANY_NAME_WL="EnterpriseDB Corporation"
PEM_CERT_EMAIL=support@enterprisedb.com
PEM_DB_SUPERUSER=enterprisedb
PEM_DB_OS_USER=
PEM_DB_OS_GROUP=
PEM_DB_POSTGRES_CONF=
PEM_WEB_SERVER_PROCESS_NAME="$PEM_BRANDING_EDB_WL"pem
PEM_WEB_SERVER_PROCESS_NAME_UPPER=`echo $PEM_WEB_SERVER_PROCESS_NAME | tr /a-z/ /A-Z/`
PEM_INSTALLATION_TYPE_PROVIDED=0
PEM_SERVER_CRT_FILE="$PEM_BASE_DIR/resources/server-pem.crt"
PEM_WEB_REMOVE_OLD_SESSIONS=0
PEM_PYTHON=python3
PEM_PYTHON_EXECUTABLE=/usr/bin/${PEM_PYTHON}
PEM_ENABLE_LOGGING=1

# These values are now hardcoded:

WEB_SERVER_NAME=httpd
WEB_SERVER_SERVICE_NAME=httpd
WEB_SERVER_SERVICE_CONFIG_PATH=/etc/httpd/conf.d
WEB_SERVER_INSTALL_PATH="/usr/sbin"
WEB_PEM_SETUP_FILE="$PEM_BASE_DIR/web/setup.py"
WEB_PEM_WSGI_FILE="$PEM_BASE_DIR/web/pem.wsgi"
WEB_PEM_PYCONFIG_FILE="$PEM_BASE_DIR/web/config_setup.py"
WEB_PEM_CONFIG_LOCAL_FILE="$PEM_BASE_DIR/web/config_local.py"
WEB_PEM_SERVICE_CONFIG_PATH=/$PEM_BRANDING_EDB_WL-ssl-pem.conf

AGENT_INSTALL_PATH="$PEM_BASE_DIR/agent"

SERVICES_PATH=""
UNATTENDED_MODE=0

WD=$PWD
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PEM_CONFIG_ARGUMENTS_FILE="${BASE_DIR}/../share/.install-config"
DEFAULT_PEM_SERVER_SSL_PORT=8443
PEM_SERVER_SSL_PORT=${PEM_SERVER_SSL_PORT:=${DEFAULT_PEM_SERVER_SSL_PORT}}

# This value will be used for postgresql database
DB_HOST=127.0.0.1

RAR_SHELL_BASH=0
RAR_SHELL=`ps e | grep $$ | grep -v grep | awk '{print $5}'`
if [ x"${RAR_SHELL}" = x"/bin/bash" -o x"${RAR_SHELL}" = x"bash" -o x"${RAR_SHELL}" = x"-bash" ]; then
	RAR_SHELL_BASH=1
fi

## Check presence of tput utility on the system
RAR_TPUT_PRESENT=0
which tput > /dev/null 2>&1
if [ $? -eq 0 -a ${RAR_SHELL_BASH} -eq 1 ]; then
	RAR_TPUT_PRESENT=1
fi

## Check presence of stty utility on the system
RAR_STTY_PRESENT=0
which stty > /dev/null 2>&1
if [ $? -eq 0 -a ${RAR_SHELL_BASH} -eq 1 ]; then
	RAR_STTY_PRESENT=1
fi
RAR_STTY_OUTPUT=

# ---------------------------
# Message related variables
# ---------------------------

export MSG_DEBUG=0
export MSG_EMPTY=1
export MSG_INFO=2
export MSG_WARN=3
export MSG_TEST=4
export MSG_TEST_VALUE=5
export MSG_CRITICAL=6

# Not part of the above enum
export MSGIsTesting=0

export TIME_STAMP=$(date +"%Y-%m-%d-%H:%M:%S")
export MSG_LOG_DIR=${BASE_DIR}/../logs
export MSG_LOG_FILE=${MSG_LOG_DIR}/configure-pem-server-${TIME_STAMP}.log

MSG_INPUT_INSTALLATION_TYPE="Install type: 1:Web Services and Database, 2:Web Services 3: Database "
MSG_INPUT_PG_INSTALL_PATH="Enter local database server installation path (i.e. /usr/${PEM_BRANDING_EDB_WL}/as12 , or /usr/pgsql-12, etc.) "
MSG_INPUT_SUPERUSER="Enter database super user name "
MSG_INPUT_DB_HOST="Enter database server host address "
MSG_INPUT_PORT="Enter database server port number "
MSG_INPUT_PASSWORD="Enter database super user password "
MSG_INPUT_CIDR_ADDR="Please enter CIDR formatted network address range that agents will connect to the server from, to be added to the server's pg_hba.conf file. For example, 192.168.1.0/24 "
MSG_INPUT_DB_UNIT_FILE="Enter database systemd unit file or init script name (i.e. $PEM_BRANDING_EDB_WL-as-12 or postgresql-12, etc.) "
MSG_INPUT_AGENT_CERTIFICATE_PATH="Please specify agent certificate path (Script will attempt to create this directory, if it does not exists) "
MSG_ERROR_PSQL_LIBS_VALIDATE="
Either database server installation path is incorrect or the required psql binary is not installed.
If the psql binary is not installed, then install any one of the following packages:
edb-as<X>-server-client
postgresql<X>
Where, X is version 12 or above."

# This will set LC_ALL and LC_CTYPE with LANG value if locale is not properly set.
LC_ALL=${LC_ALL:-${LANG}}
LC_CTYPE=${LC_CTYPE:-${LANG}}
export LC_ALL LC_CTYPE

# ---------------------
# Web server variables
# ---------------------

WEB_PEM_CONFIG_FILE="${WEB_SERVER_SERVICE_CONFIG_PATH}/${PEM_BRANDING_EDB_WL}-pem.conf"
WEB_PEM_SSL_CONFIG_FILE="${WEB_SERVER_SERVICE_CONFIG_PATH}/${PEM_BRANDING_EDB_WL}-ssl-pem.conf"
WEB_DEFAULT_PORT_CONFIG_FILE="${WEB_SERVER_SERVICE_CONFIG_PATH}/${PEM_BRANDING_EDB_WL}-ssl-pem.conf"
IS_WEB_CONFIGURE_ADD_ON_SERVICE=0
PEM_DB_SERVICE_FLAG="-w"
### Platform releated service functions ###

InitServiceDetails()
{
	export PLATFORM_SERVICE_NAME=systemctl
}

CheckServiceExist()
{
	SERVICE_NAME=$1

	if [ ! -f /etc/init.d/${SERVICE_NAME}* ] &&
		[ ! -f /usr/lib/systemd/system/${SERVICE_NAME}.service ] &&
		[ ! -f /etc/systemd/system/${SERVICE_NAME}.service ]; then
			Message ${MSG_CRITICAL} "Service - ${SERVICE_NAME} does not exist"
	fi
}

InitServiceDetails

### Platform releated service functions ###

### Platform releated service functions - with systemd ###

ExecuteServiceCommand()
{
	ACTION=$1
	SERVICE_NAME=$2
	EXTRA_OPTION=$3 #If this is set it would ignore and will not abort if any issues

	# Check if service file exist or not
	CheckServiceExist ${SERVICE_NAME}
	SERVICE_COMMAND="${PLATFORM_SERVICE_NAME} ${ACTION} ${SERVICE_NAME}"

	Message ${MSG_INFO} "Executing ${SERVICE_COMMAND}"
	COMMAND_OUT=$(${SERVICE_COMMAND})
        if [ $? -ne 0 ]; then
                if [ "${EXTRA_OPTION}" != "ignore" ]; then
                        Message $MSG_CRITICAL "Error: ${COMMAND_OUT} failed"
                fi
        fi
}

### Platform releated service functions - with systemd ###

### Web server functions ###

PreConfogureWebModWSGIModules()
{
	echo "This is not required for rpm installation i.e for httpd web service" > /dev/null 2>&1

}

PreConfigureWebServerSSLModules()
{
	echo "This is not required for rpm installation i.e for httpd web service" > /dev/null 2>&1
}

ConfigureWebServerGNUTLSConf()
{
	echo "This is not required for rpm installation i.e for httpd web service" > /dev/null 2>&1
}

InsertWebServerSSLConfModule()
{
	echo "This is not required for rpm installation i.e for httpd web service" > /dev/null 2>&1
}

UninstallWebServerModules()
{
	echo "This is not required for rpm installation i.e for httpd web service" > /dev/null 2>&1
}

GetWebServerSSLFreePort()
{
        SERVER_SSL_PORT=${PEM_SERVER_SSL_PORT}

        while [ ${SERVER_SSL_PORT} -gt 0 ] && [ ${SERVER_SSL_PORT} -lt 65535 ];  do
                RET=$(netstat -tulpn | grep LISTEN | grep ${SERVER_SSL_PORT})  > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                        break;
                fi

                SERVER_SSL_PORT=$(expr ${SERVER_SSL_PORT} + 1)
        done

        echo ${SERVER_SSL_PORT}
}

ConfigureRedirectDefaultWebPort()
{
        if [ ! -f ${WEB_DEFAULT_PORT_CONFIG_FILE} ]; then
                Message ${MSG_CRITICAL} "Webserver File not found : ${WEB_DEFAULT_PORT_CONFIG_FILE}"
        fi

	grep -o "<VirtualHost _default_:80>" edb-ssl-pem.conf >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "<VirtualHost _default_:80>" >> ${WEB_DEFAULT_PORT_CONFIG_FILE}
		echo "</VirtualHost>" >> ${WEB_DEFAULT_PORT_CONFIG_FILE}
	fi

        grep -o "<Location \"\/pem\">" ${WEB_DEFAULT_PORT_CONFIG_FILE} >/dev/null 2>&1
        if [ $? -ne 0 ]; then
                PEM_BACKUP_NUMBER=$RANDOM
                Message $MSG_INFO "Taking backup of ${WEB_DEFAULT_PORT_CONFIG_FILE}"
                cp ${WEB_DEFAULT_PORT_CONFIG_FILE} ${WEB_DEFAULT_PORT_CONFIG_FILE}.${PEM_BACKUP_NUMBER}

                location_opentag="<Location \"/pem\">"
                location_content1="RewriteEngine On"
                location_content2="RewriteCond %{SERVER_PORT} 80"
		location_content3="RewriteRule ^(.*)$ https://%{HTTP_HOST}:${PEM_SERVER_SSL_PORT}%{REQUEST_URI} [L,R=301]"
                location_closetag="</Location>"

		sed -e "/^<VirtualHost _default_:80>/,/<\/VirtualHost>/ { /<\/VirtualHost>/ i\\${location_opentag} \\n\\t ${location_content1} \\n\\t ${location_content2} \\n\\t ${location_content3} \\n ${location_closetag}" -e '}' ${WEB_DEFAULT_PORT_CONFIG_FILE} > /tmp/$$.tmp
                cp /tmp/$$.tmp ${WEB_DEFAULT_PORT_CONFIG_FILE}
                rm -rf /tmp/$$.tmp
        fi
}

# This function is used only for SUSE - Apache2 server
ConfigureWebAddonServices()
{
	if [ "${IS_WEB_CONFIGURE_ADD_ON_SERVICE}" = "1" ]; then
		WEB_ENMOD_CMD=/usr/sbin/a2enmod
		command -v ${WEB_ENMOD_CMD} > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			Message ${MSG_CRITICAL} "${WEB_ENMOD_CMD} command not found."
		fi

                ${WEB_ENMOD_CMD} rewrite > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                        Message ${MSG_CRITICAL} "${WEB_ENMOD_CMD} rewrite command failed."
                fi
        fi
}

### Web server functions ###

HandleOpensslRndFile()
{
	echo "This is not required for rpm installation i.e for openssl 1.1.1 and above" > /dev/null 2>&1
}

if [ ! -d ${MSG_LOG_DIR} ]; then
	mkdir ${MSG_LOG_DIR}
	if [ $? -ne 0 ]; then
		echo "[Error] - Unable to create ${MSG_LOG_DIR} folder"
	fi
	touch ${MSG_LOG_FILE}
fi

if [ $? -ne 0 ]; then
	echo "[Error] - Unable to create ${MSG_LOG_FILE} file"
fi

LogMessage()
{
	MessageText=$1
	echo "${prefix} ${MessageText}" | tee -a ${MSG_LOG_FILE} 2>&1
}

LogMessageVoid()
{
	LogMessage "$*" > /dev/null 2>&1
}

# $1 - Heading text
MessageHeading()
{
	LogMessage ""
	LogMessage "-----------------------------------------------------"
	LogMessage "$1"
	LogMessage "-----------------------------------------------------"
}

# $1 - Message type
# $2 - Message text; in case of MSG_EMPTY, this value is ignored
# $3 - Suppress message; do not print any messages

Message()
{
	prefix="--> "
	MessageType="$1"
	MessageText="$2"
	blnSuppressMessage="$3"

	if [[ ! -z "${blnSuppressMessage}" ]]; then
		return
	fi


	# If no value given for a test condition message, ensure the next message appears on the next line
	if [[ "${MSGIsTesting}" -eq 1 && "${MessageType}" != "${MSG_TEST_VALUE}" ]];
	then
		MSGIsTesting=0
		LogMessage "[SKIPPING: NO VALUE PROVIDED]"
	fi


	case ${MessageType} in
		"${MSG_DEBUG}")
			if [[ -n "${VERBOSE}" ]]; then
				prefix="${prefix} [Debug]"
				LogMessage "${prefix} ${MessageText}"
			fi
			;;
		"${MSG_EMPTY}")
			LogMessage;
			;;
		"${MSG_INFO}")
			prefix="${prefix} [Info]"
			LogMessage "${prefix} ${MessageText}"
			;;
		"${MSG_WARN}")
			prefix="${prefix} [Warning]"
			LogMessage "${prefix} ${MessageText}"
			;;
		"${MSG_TEST}")
			MSG_IsTesting=1
			prefix="${prefix} [Test]"
			LogMessage "${prefix} ${MessageText}"
			;;
		"${MSG_TEST_VALUE}")
			LogMessage "$2"
			;;
		"${MSG_CRITICAL}")
			prefix="${prefix} [Error]"

			MessageHeading "CRITICAL ERROR"
			LogMessage "${prefix} Script exiting because of the following error:"
			LogMessage "${2}"
			LogMessage "Current working directory and stack is:"
			dirs -l -v
			# Stack trace
			{
				local i
				i=0
				while caller $i
				do
					i=$((i+1))
				done
			}
			LogMessage "${prefix} ${MessageText}"
			exit
			;;
		?)
			Usage
			exit
			;;
	esac
}

# Make sure only root can run this script:
if [ "$(id -u)" != "0" ]; then
	echo
	Message ${MSG_CRITICAL} "This script must be run as root"
fi

Info()
{
	LRAR_SHOW_IN_ANYCASE=$1
	if [ x"${LRAR_SHOW_IN_ANYCASE}" = x"1" ]; then
		shift
	fi
	if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]; then
		echo -e "\E[32;49m""$*" && tput sgr0
	else
		echo $*
	fi
}

Usage()
{
	Additional_COMPS=""
	LRAR_SCRIPTNAME=`basename $0`
	MessageHeading "USAGE: ${PEM_BASE_DIR}/bin/${LRAR_SCRIPTNAME} <options>"
	Info  1 "options:"
	Info  1 "   -acp | --pemagent-certificate-path		<PEM agent certificate path>		"
	Info  1 "   -ci  | --cidr-address			<CIDR Address>				"
	Info  1 "   -dbi | --db-install-path			<Database server installation path>	"
	Info  1 "   -ds  | --db-unitfile				<Database server unit file name>		"
	Info  1 "   -ho  | --host				<Database server host address>		"
	Info  1 "   -p   | --port				<Database server port>			"
	Info  1 "   -ps  | --pemagent-servicename		<PEM agent service name>		"
	Info  1 "   -sp  | --superpassword			<Database superuser password>		"
	Info  1 "   -su  | --superuser				<Database superuser>			"
	Info  1 "   -t   | --type				<Install type: 1:Web Services and Database, 2:Web Services 3: Database>		"
	Info  1 "   -un  | --uninstall-pem-server		<Uninstall PEM server>			"
	Info  1 "   -h   | --help				<help>					"

	if [ x"$1" != x"" ]; then
		exit $1
	fi
}

# Process command line switches
ProcessCommandLine()
{
	RAR_NO_PROCD_CMD=1
	case $1 in
		-acp|--pemagent-certificate-path)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			AGENT_CERTIFICATE_PATH=$2
			AGENT_CERTIFICATE_PATH_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-ci|--cidr-address)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			CIDR_ADDR=$2
			CIDR_ADDR_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-dbi|--db-install-path)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			PG_INSTALL_PATH=$2
			PG_INSTALLPATH_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-ds|--db-unitfile)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			DB_UNIT_FILE=$2
			DB_UNIT_FILE_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-ho|--host)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			HOST=$2
			DB_PGHOST_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-p|--port)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			PORT=$2
			DB_PGPORT_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-ps|--pemagent-servicename)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			AGENT_SERVICE_NAME=$2
			AGENT_SERVICE_NAME_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-sp|--superpassword)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			SUPER_PASSWORD=$2
			DB_SUPER_PASSWORD_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-su|--superuser)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			SUPERUSER=$2
			DB_SUPERUSER_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-t|--type)
			if [ ${#} -lt 2 ]; then
				Usage 2
			fi
			PEM_INSTALLATION_TYPE=$2
			PEM_INSTALLATION_TYPE_PROVIDED=1
			RAR_NO_PROCD_CMD=2
			;;
		-un|--uninstall-pem-server)
			UNINSTALL_PEM_SERVER_PROVIDED=1
			RAR_NO_PROCD_CMD=1
			;;
		-h|--help)
			Usage 0
			;;
		*)
			RAR_NO_PROCD_CMD=0
			Message $MSG_CRITICAL "Unknown command-line argument:'$1' (Ignored)"
			Usage 1
			;;
	esac
}

Question()
{
	if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -eq 2 ]; then
		echo -en "\E[34;49m"$1 "\E[32;49m"[ $2 ] "\E[34;49m": && tput sgr0
	elif [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]; then
		echo -en "\E[34;49m"$* && tput sgr0
	else
		echo $*
	fi
}

ReadValue()
{

	QUESTION=${1}
	VARIABLE=${2}
	DEFAULT_VALUE=${3}
	VALIDATOR=${4}
	DESC_VARIABLE=${5}
	RETURN_VALUE=0

	if [ ${UNATTENDED_MODE} -eq 1 ]; then

		eval ${VARIABLE}=${DEFAULT_VALUE}
		if [ x"${VALIDATOR}" != x"" -a x"${VALIDATOR}" != x" " ]; then
			${VALIDATOR} "${!VARIABLE}" 1
			if [  $? -ne 1 ]; then
				Message $MSG_CRITICAL "\"${!VARIABLE}\" is not valid value for the variable \"${DESC_VARIABLE}\""
			fi
		fi
		return 1
	fi

	while [ ${RETURN_VALUE} -ne 1 ]; do
		Question "${1}" "${DEFAULT_VALUE}"
		RETURN_VALUE=1
		read ${VARIABLE}
		# if no input provided, set the variable value to the default value (if any)
		if [ x"${!VARIABLE}" = x"" -a x"${DEFAULT_VALUE}" != x"" ]; then
			eval ${VARIABLE}=${DEFAULT_VALUE} 2>/dev/null
		fi
		if [ x"${VALIDATOR}" != x"" -a x"${VALIDATOR}" != x" " ]; then
			${VALIDATOR} "${!VARIABLE}" 1
			RETURN_VALUE=$?
		fi
	done
	return ${RETURN_VALUE}
}

ReadPassword()
{
	if [ ${RAR_STTY_PRESENT} -eq 1 ]; then
		RAR_STTY_OUTPUT=`stty -g`
		stty -echo
		ReadValue "${1}" "${2}" "${3}" "${4}" "${5}"
		stty ${RAR_STTY_OUTPUT}
		RAR_STTY_OUTPUT=
	else
		ReadValue "${1}" "${2}" "${3}" "${4}" "${5}"
	fi
}

AddNewLine()
{
	LINE_NUMBER=$1
	TEXT=$2
	FILE_NAME=$3

	sed -i "${LINE_NUMBER}s|^|${TEXT}\n|" ${FILE_NAME}
}

GetDBName()
{
	for dbname in postgres edb template1
	do
		RESULT=$(PSQLExecuteVoid "SELECT version();" "${dbname}")
		if [ $? -eq 0 ]; then
			RESULT=$dbname
			break
		fi
	done

	if [ -z "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Cannot identify the database name."
	fi

	echo $RESULT
}

GetDBDataDirectoryPath()
{
	RESULT=$(PSQLExecuteCMD "SHOW data_directory;" "${PGDATABASE}")
	if [ -z "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Cannot identify the database data directory path"
	fi

	if [ ! -d "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Unable to locate the database data directory path - ${RESULT}"
	fi

	echo ${RESULT}
}

GetDBConfFileName()
{
	RESULT=$(PSQLExecuteCMD "SHOW config_file;" "${PGDATABASE}")

	if [ -z "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Cannot identify the database config file"
	fi

	if [ ! -e "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Unable to locate the database config file - ${RESULT}"
	fi

	echo ${RESULT}
}

GetDBHbaFileName()
{
	RESULT=$(PSQLExecuteCMD "SHOW hba_file;" "${PGDATABASE}")

	if [ -z "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Cannot identify the database hba config file"
	fi

	if [ ! -e "${RESULT}" ]; then
		Message ${MSG_CRITICAL} "Unable to locate the database hba config file - ${RESULT}"
	fi

	echo ${RESULT}
}

PEMPSQLEnviromentVariable()
{
	FILE_META=$(ls -ld "${PG_DATA_DIR}/PG_VERSION")
	export PEM_DB_OS_USER=$(echo ${FILE_META} | cut -d " " -f3) # Username
	export PEM_DB_OS_GROUP=$(echo ${FILE_META} | cut -d " " -f4) # Groupname
}

PSQLEnviromentVariable()
{
	# Check if we can login to database or not
	# Before setting PGDATABSE variable
	out=`PGPASSWORD=${SUPER_PASSWORD} "${PG_INSTALL_PATH}/bin/psql" -c "SELECT 1" postgres --host=${HOST} --port=${PORT} -U ${SUPERUSER} 2>&1`
	if [ $? -ne 0 ]; then
		echo ${out} | tee -a ${MSG_LOG_FILE} 2>&1
		Message ${MSG_CRITICAL} "Failed to verify the parameters"
		# exit is explicilty required as child process isd
		exit 1
	fi

	# Psql predefined system variables
	export PGPASSWORD=${SUPER_PASSWORD}
	export PGHOST=${HOST}
	export PGPORT=${PORT}
	export PGUSER=${SUPERUSER}

	export PGDATABASE=$(GetDBName)


	if [ "${IS_TYPE_DB}" = "1" ]; then
		# Psql configuration vaiables - user defined
		export PG_DATA_DIR=$(GetDBDataDirectoryPath)
        	export PG_CONFIG_FILE=$(GetDBConfFileName)
		export PG_HBA_FILE=$(GetDBHbaFileName)
	fi
}

PSQLExecuteFile()
{
	CMD="${1}"
	OPTIONAL_ARG="${3}"
	if [ ! -z "${2}" ]; then
		LogMessageVoid "[QUERY FILE on ${2}] ${1}"
                OPTIONAL_ARG="-d ${2} ${OPTIONAL_ARG}"
	else
		LogMessageVoid "[QUERY FILE] ${1}"
	fi

        # Database options
	LogMessageVoid "[QUERY OUTPUT]"
	"${PG_INSTALL_PATH}/bin/psql" -At -v ON_ERROR_STOP=1 --no-psqlrc ${OPTIONAL_ARG} -f "${CMD}" | tee -a ${MSG_LOG_FILE} 2>&1
}

PSQLExecuteCMD()
{
	CMD="${1}"
	OPTIONAL_ARG="${3}"
	if [ ! -z "${2}" ]; then
		if [ ${PEM_ENABLE_LOGGING} -eq 1 ]; then
			LogMessageVoid "[QUERY on ${2}] ${1}"
		fi

		OPTIONAL_ARG="-d ${2} ${OPTIONAL_ARG}"
	else
		if [ ${PEM_ENABLE_LOGGING} -eq 1 ]; then
			LogMessageVoid "[QUERY] ${1}"
		fi
	fi

	if [ ${PEM_ENABLE_LOGGING} -eq 1 ]; then
		# Database options
		LogMessageVoid "[QUERY OUTPUT]"
		"${PG_INSTALL_PATH}/bin/psql" -At -v ON_ERROR_STOP=1 --no-psqlrc ${OPTIONAL_ARG} -c "${CMD}" | tee -a ${MSG_LOG_FILE} 2>&1
	else
		"${PG_INSTALL_PATH}/bin/psql" -At -v ON_ERROR_STOP=1 --no-psqlrc ${OPTIONAL_ARG} -c "${CMD}" 2>&1
	fi
}

PSQLExecuteVoid()
{
	PSQLExecuteCMD "$1" "$2" "$3" 2>/dev/null
}

PSQLExecuteSuppressLogVoid()
{
	# Do not log sensitive information, so disable the logging
	PEM_ENABLE_LOGGING=0
	PSQLExecuteCMD "$1" "$2" "$3"
	# Enable the logging again
	PEM_ENABLE_LOGGING=1
}

ExecuteUpdateSchema()
{

	CURRENT_SCHEMA_VERSION=$1

	pushd ${BASE_DIR}/../share/upgrades > /dev/null

		FILES=`find * | cut -f1 -d'.'`

		for f in ${FILES}
		do
			if [ $f -gt "${CURRENT_SCHEMA_VERSION}" ]; then
				RESULT=$(PSQLExecuteFile "$BASE_DIR/../share/upgrades/${f}.sql" "pem")
			fi
		done
	popd > /dev/null
}


CheckSSLUtilsPresent()
{
	SSLUTILS_EXTENSION_PRESENT=$(PSQLExecuteCMD "SELECT CASE WHEN count(*) > 0 THEN 1 ELSE 0 END FROM pg_catalog.pg_available_extensions WHERE name='sslutils';")

	if [ ${SSLUTILS_EXTENSION_PRESENT} -ne 0 ]; then
		SSLUTILS_EXTENSION_V_PRESENT=$(PSQLExecuteCMD "SELECT CASE WHEN count(*) = 0 THEN 0 ELSE 1 END FROM pg_catalog.pg_extension_update_paths('sslutils') WHERE target = '1.3';")
		if [ ${SSLUTILS_EXTENSION_V_PRESENT} = 0 ];
		then
			Message ${MSG_CRITICAL} "Older version of SSLUtils extension was found in the selected database server. This extension (version: 1.3) must be installed before the server can be used by the ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager Server."
		fi

		SSLUTILS_ALREADY_EXISTS=$(PSQLExecuteCMD "SELECT count(*) FROM pg_proc WHERE proname='openssl_csr_to_crt' AND proargtypes = '25 25 25'::OIDVECTOR AND prosrc='openssl_csr_to_crt' AND NOT proretset AND probin = '\${libdir}/sslutils';")

		if [ ${SSLUTILS_ALREADY_EXISTS} = 0 ]; then
			PSQLExecuteCMD "CREATE EXTENSION IF NOT EXISTS sslutils;"

			if [ $? -ne 0 ]; then
				Message ${MSG_CRITICAL} "The SSLUtils extension was not found in the selected database server. The latest version of this extension must be installed before the server can be used by the ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager Server."
			fi
		fi
	else
		Message ${MSG_CRITICAL} "The SSLUtils extension was not found in the selected database server. The latest version of this extension must be installed before the server can be used by the ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager Server."
	fi
}

ConfigureDBServer()
{
	Message ${MSG_INFO} "Configuring database server."

	# Check whether the database is running or not:
	${PG_INSTALL_PATH}/bin/pg_isready -U ${SUPERUSER} -h ${HOST} -p ${PORT} -d ${PGDATABASE} -q
	if [ $? -ne 0 ]; then
		Message ${MSG_CRITICAL} "Error connecting to the database: Database is not running."
	fi

	# Check whether we can connect to the database or not:
	PG_CHECK_HBA_IS_CORRECT=$(PSQLExecuteCMD "SELECT 1;" "" "-q")
	if [ "$PG_CHECK_HBA_IS_CORRECT" -ne "1" ]; then
		Message ${MSG_CRITICAL} "Error connecting to the database: Please check pg_hba.conf file."
	fi

	PGUSER_IS_SUPERUSER=$(PSQLExecuteCMD "SELECT (CASE WHEN rolsuper THEN 1 ELSE 0 END) AS issuperuser FROM pg_catalog.pg_roles WHERE rolname = current_user;")
	PGUSER_CAN_CREATEDB=$(PSQLExecuteCMD "SELECT (CASE WHEN rolcreatedb THEN 1 ELSE 0 END) AS cancreatedb FROM pg_catalog.pg_roles WHERE rolname = current_user;")
	PGUSER_CAN_CREATEROLE=$(PSQLExecuteCMD "SELECT (CASE WHEN rolcreaterole THEN 1 ELSE 0 END) AS cancreaterole FROM pg_catalog.pg_roles WHERE rolname = current_user;")

	if [ ${PGUSER_CAN_CREATEROLE} -eq 0 ] ||  [ ${PGUSER_IS_SUPERUSER} -eq 0 ]; then
		Message ${MSG_CRITICAL} "The specified user does not have permissions to create another role."
	fi

	PEM_DB_EXISTS=$(PSQLExecuteCMD "SELECT count(*) FROM pg_catalog.pg_database WHERE datname = 'pem';")
	USER_PG_HBA=$(PSQLExecuteCMD "SELECT pg_catalog.quote_ident(current_user);")

	if [ ${PEM_DB_EXISTS} -eq 0 ]; then

		if [ ${PGUSER_CAN_CREATEDB} -eq 0 ] ||  [ ${PGUSER_IS_SUPERUSER} -eq 0 ]; then
			Message ${MSG_CRITICAL} "The specified user does not have permissions to create a database."
		fi

		# Check whether sslutils extension is available or not before creating the database:
		# Otherwise, the script will fail in next run, after sslutils is installed:
		CHECK_SSLUTILS_AVAILABLE=$(PSQLExecuteCMD "SELECT count(*) FROM pg_available_extensions WHERE name='sslutils';")
		if [ ${CHECK_SSLUTILS_AVAILABLE} -eq 0 ]; then
			Message ${MSG_CRITICAL} "The SSLUtils extension was not found in the selected database server. This extension must be installed before the server can be used by the ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager Server."
		fi

		# Now, proceed with database and extension creation:
		PSQLExecuteCMD "CREATE DATABASE pem;"
		PSQLExecuteCMD "CREATE LANGUAGE plpgsql;"
		PSQLExecuteCMD "CREATE EXTENSION IF NOT EXISTS sslutils;" "pem"
		# Trap error in this step:
		if [ $? -ne 0 ]; then
			# First drop the database, otherwise script will skip this part in next run:
			PSQLExecuteCMD "DROP DATABASE IF EXISTS pem;"
			# Now, give error and exit. The code should never reach here:
			Message ${MSG_CRITICAL} "Error installing SSLUtils extension. Please check database server logs."
		fi

		# Check whether hstore extension is available or not Otherwise, the script will fail.
		CHECK_HSTORE_AVAILABLE=$(PSQLExecuteCMD "SELECT count(*) FROM pg_available_extensions WHERE name='hstore';" "pem")

		if [ ${CHECK_HSTORE_AVAILABLE} -eq 0 ]; then
			Message ${MSG_CRITICAL} "The hstore extension was not found in the selected database server. This extension must be installed on pem database before the server can be used by the ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager Server."
		fi

		PSQLExecuteFile "$BASE_DIR/../share/pemserver.sql" "pem"
		PSQLExecuteFile "$BASE_DIR/../share/postgresexpert.sql" "pem"
		PSQLExecuteCMD "DO \$\$ BEGIN PERFORM \$SQL\$GRANT pem_admin TO \$SQL\$ || pg_catalog.quote_ident(current_user); END \$\$ LANGUAGE 'plpgsql';"

		# Generate certificates
		GenerateCertificates

	else
		Message $MSG_INFO "Database pem already exists."

		HAS_PRIVILEGE_ON_PEM=$(PSQLExecuteCMD "SELECT (CASE WHEN pg_catalog.has_database_privilege('pem', 'TEMP') AND pg_catalog.has_database_privilege('pem', 'CREATE') AND pg_catalog.has_database_privilege('pem', 'CONNECT') THEN 1 ELSE 0 END);")

		if [ ${HAS_PRIVILEGE_ON_PEM} -eq 0 ]; then
			Message ${MSG_CRITICAL} "The specified user '${SUPERUSER}' does not have complete access rights to the 'pem' database."
		fi

		PEM_SCHEMA_EXISTS=$(PSQLExecuteCMD "SELECT COUNT(*) FROM pg_catalog.pg_namespace WHERE nspname = 'pem';" "pem")

		# Check whether hstore extension is available or not Otherwise, the script will fail.
		CHECK_HSTORE_AVAILABLE=$(PSQLExecuteCMD "SELECT count(*) FROM pg_available_extensions WHERE name='hstore';" "pem")

		if [ ${CHECK_HSTORE_AVAILABLE} -eq 0 ]; then
			Message ${MSG_CRITICAL} "The hstore extension was not found in the selected database server. This extension must be installed on pem database before the server can be used by the $PEM_BRANDING_EDB_CAPS_WL Postgres Enterprise Manager Server."
		fi

		if [ ${PEM_SCHEMA_EXISTS} -eq 1 ]; then
			HAS_ALL_ACCESS_ON_PEM_SCHEMA=$(PSQLExecuteCMD "SELECT (CASE WHEN pg_catalog.has_schema_privilege('pem', 'CREATE') AND pg_catalog.has_schema_privilege('pem', 'USAGE') THEN 1 ELSE 0 END);" "pem")

			if [ ${HAS_ALL_ACCESS_ON_PEM_SCHEMA} = 0 ]; then
				Message ${MSG_CRITICAL} "The specified user '${SUPERUSER}' does not have complete access rights to the 'pem' schema."
			fi

			PEM_SERVER_SCHEMA_VERSION=$(PSQLExecuteCMD "SELECT pem.schema_version();" "pem")

			if [ -n "${PEM_SERVER_SCHEMA_VERSION}" ]; then
				PEMDATA_PEMHISTORY_SCHEMAS_EXIST=$(PSQLExecuteCMD "SELECT (CASE WHEN COUNT(*) = 2 THEN 1 ELSE 0 END) FROM pg_catalog.pg_namespace WHERE nspname = 'pemdata' OR nspname = 'pemhistory';" "pem")
			fi

			if [ -z "${PEM_SERVER_SCHEMA_VERSION}" ] || [ ${PEMDATA_PEMHISTORY_SCHEMAS_EXIST} = 0 ]; then
				Message ${MSG_CRITICAL} "Existing 'pem' schema found, but it is not compatible with the ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager server."
			fi

			if [ -n "${PEM_SERVER_SCHEMA_VERSION}" ]; then
				# Execute upgrade schema files
				ExecuteUpdateSchema ${PEM_SERVER_SCHEMA_VERSION}
			fi
		else
			PSQLExecuteFile "$BASE_DIR/../share/pemserver.sql" "pem"
			PSQLExecuteFile "$BASE_DIR/../share/postgresexpert.sql" "pem"
			PSQLExecuteCMD "DO \$\$ BEGIN PERFORM \$SQL\$GRANT pem_admin TO \$SQL\$ || pg_catalog.quote_ident(current_user); END \$\$ LANGUAGE 'plpgsql';"
		fi

		# Generate certificates
		GenerateCertificates
	fi

	# Get local machine ip address
	MACHINE_IP_ADDR=`ip -4 route get 12.12.12.12 | awk {'print $7'} | head -1 | tr -d '\n'`
	# If network is down then, Machine ip will be same as DB_HOST
	if [ -z ${MACHINE_IP_ADDR} ]; then
		MACHINE_IP_ADDR=${DB_HOST}
	fi

	# Stop database server
	#ExecuteServiceCommand stop "${DB_UNIT_FILE} ${PEM_DB_SERVICE_FLAG}"
	su - enterprisedb -c "/usr/edb/as15/bin/pg_ctl -D /var/lib/edb/as15/data stop -m fast"

	PEM_AGENT_ENTRY_EXISTS=`cat ${PG_HBA_FILE} | grep "^hostssl pem" | grep pem_agent | grep cert | wc -l`
	if [ ${PEM_AGENT_ENTRY_EXISTS} -eq 0 ]; then
		Message ${MSG_INFO} "Writing configurations in ${PG_HBA_FILE} file"
		AddNewLine 1 "# Allow local PEM agents and admins to connect to PEM server" $PG_HBA_FILE
		AddNewLine 2 "hostssl pem      +pem_user   ${MACHINE_IP_ADDR}/32  md5" ${PG_HBA_FILE}
		AddNewLine 3 "hostssl postgres +pem_user   ${MACHINE_IP_ADDR}/32  md5" ${PG_HBA_FILE}
		AddNewLine 4 "hostssl pem      +pem_user   ${DB_HOST}/32         md5" ${PG_HBA_FILE}
		AddNewLine 5 "hostssl pem      +pem_agent  ${DB_HOST}/32         cert" ${PG_HBA_FILE}
		AddNewLine 6 "# Allow remote PEM agents and users to connect to PEM server" ${PG_HBA_FILE}
		AddNewLine 7 "hostssl pem +pem_user  ${CIDR_ADDR} md5" ${PG_HBA_FILE}
		AddNewLine 8 "hostssl pem +pem_agent ${CIDR_ADDR} cert" ${PG_HBA_FILE}
		echo "host    all             ${USER_PG_HBA}             ${MACHINE_IP_ADDR}/32            md5" >> ${PG_HBA_FILE}

		Message ${MSG_INFO} "Writing configurations in ${PG_CONFIG_FILE} file"
		ReplacePlaceHolders "#ssl =.*$" "ssl = on" "${PG_CONFIG_FILE}"
		ReplacePlaceHolders "#ssl_cert_file =.*$" "ssl_cert_file = 'server.crt'" "${PG_CONFIG_FILE}"
		ReplacePlaceHolders "#ssl_key_file =.*$" "ssl_key_file = 'server.key'" "${PG_CONFIG_FILE}"
		ReplacePlaceHolders "#ssl_ca_file =.*$" "ssl_ca_file = 'root.crt'" "${PG_CONFIG_FILE}"
		ReplacePlaceHolders "#ssl_crl_file =.*$" "ssl_crl_file = 'root.crl'" "${PG_CONFIG_FILE}"
		ChangePermissionsInDataDirectory 0644 "${PG_CONFIG_FILE}"
	else
		Message ${MSG_INFO} "Skipping - configurations for ${PG_HBA_FILE} and ${PG_CONFIG_FILE} file"
	fi

	# Start database server
	#ExecuteServiceCommand start "${DB_UNIT_FILE} ${PEM_DB_SERVICE_FLAG}"
	su - enterprisedb -c "/usr/edb/as15/bin/pg_ctl -D /var/lib/edb/as15/data start"
}

ConfigurePEMAgent()
{
	if [ ! -f ${AGENT_INSTALL_PATH}/etc/agent.cfg ]; then
		PEM_SERVER_PASSWORD=${SUPER_PASSWORD} ${AGENT_INSTALL_PATH}/bin/pemworker --register-agent --config-dir ${AGENT_INSTALL_PATH}/etc/ --pem-server ${HOST} --pem-port ${PORT} --pem-user ${SUPERUSER} --display-name "${PEMAGENT_DISPLAY_NAME}" --cert-path ${AGENT_CERTIFICATE_PATH}

		if [ $? -ne 0 ]; then
			Message ${MSG_CRITICAL} "PEM Agent failed to register with PEM server."
		fi
		ReplacePlaceHolders "alert_threads=0" "alert_threads=1" ${AGENT_INSTALL_PATH}/etc/agent.cfg
		ReplacePlaceHolders "enable_smtp=false" "enable_smtp=true" ${AGENT_INSTALL_PATH}/etc/agent.cfg
		ReplacePlaceHolders "enable_snmp=false" "enable_snmp=true" ${AGENT_INSTALL_PATH}/etc/agent.cfg
		ReplacePlaceHolders "enable_webhook=false" "enable_webhook=true" ${AGENT_INSTALL_PATH}/etc/agent.cfg
		ReplacePlaceHolders "max_webhook_retries=0" "max_webhook_retries=3" ${AGENT_INSTALL_PATH}/etc/agent.cfg

		if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
			printf "\nca_file=/etc/ssl/certs/ca-certificates.crt" >> ${AGENT_INSTALL_PATH}/etc/agent.cfg
		fi
		export REQUIRED_REGISTER_SERVER_WITH_PEM="yes"
	else
		# webhook is introduced in PEM 8.0 so in upgrade from 7.x, update the agent.cfg file
		# to support the webhook by default in the agent installed on pem server
		ret=$(grep -c "enable_webhook=true" ${AGENT_INSTALL_PATH}/etc/agent.cfg)
		if [ ${ret} -eq 0 ]; then
			# Does not contain enable_webhook so add entry
			echo "" >> ${AGENT_INSTALL_PATH}/etc/agent.cfg
			echo "enable_webhook=true" >> ${AGENT_INSTALL_PATH}/etc/agent.cfg
		fi

		ret=$(grep -c "max_webhook_retries=3" ${AGENT_INSTALL_PATH}/etc/agent.cfg)
		if [ ${ret} -eq 0 ]; then
			# Does not contain max_webhook_retries so add entry
			echo "" >> ${AGENT_INSTALL_PATH}/etc/agent.cfg
			echo "max_webhook_retries=3" >> ${AGENT_INSTALL_PATH}/etc/agent.cfg
		fi
	fi
}


RegisterServerWithPEM()
{

    if [  ${IS_TYPE_WEB} -eq 1 ] && [ ${IS_TYPE_DB} -eq 0 ];  then
        Message ${MSG_INFO} "Skipping - Registering database server with PEM server when installing a web server."
    else
        Message ${MSG_INFO} "Registering database server with PEM server."

        AGENT_ID=`grep 'agent_id=' ${AGENT_INSTALL_PATH}/etc/agent.cfg | cut -f2 -d'='`

        ENC_PASSWORD=`PEM_ENC_PAYLOAD=${SUPER_PASSWORD} $BASE_DIR/../encryptor/bin/pemEncryptor`

        #DBNAME=`GetDBName`
        DBNAME=${PGDATABASE}

        if [ ${IS_TYPE_WEB} -eq 1 ]; then
            # In case, were also installing both web & database mode, we should
            # use the ${HOST} value as the PEM-Server host.
            PEM_HOST=${HOST}
        else
            # Otherwise - fallback to use the machine ip address as the server host.
            PEM_HOST=${MACHINE_IP_ADDR}
        fi

        PSQLExecuteSuppressLogVoid "SELECT pem.startup('Postgres Enterprise Manager Server', '${PEM_HOST}', '${HOST}', ${PORT}, '${DBNAME}', 2, '${SUPERUSER}', '${ENC_PASSWORD}', 'PEM Server Directory', ${AGENT_ID}, '${DBNAME}');" "pem"

        if [ $? -ne 0 ]; then
            Message ${MSG_CRITICAL} "Failed to register DB Server with PEM Server."
        fi

        cp ${BASE_DIR}/../resources/pem-server-random.sql.in ${BASE_DIR}/../resources/pem-server-random.sql
        ReplacePlaceHolders ENC_PASSWORD ${ENC_PASSWORD} ${BASE_DIR}/../resources/pem-server-random.sql
        ReplacePlaceHolders AGENT_ID ${AGENT_ID} ${BASE_DIR}/../resources/pem-server-random.sql
        ReplacePlaceHolders PGPORT ${PORT} ${BASE_DIR}/../resources/pem-server-random.sql

        PSQLExecuteFile "${BASE_DIR}/../resources/pem-server-random.sql" "pem"

        rm -f ${BASE_DIR}/../resources/pem-server-random.sql
    fi
}

GenerateSSLCertificateForWebServer()
{
	Message ${MSG_INFO} "Generating the SSL certificates for the web server."

	# Create the certificate signing request
	pushd "${BASE_DIR}/../resources/" > /dev/null

	PEM_APP_HOST=${PEM_APP_HOST:=HTTPD-${PEM_BRANDING_EDB_CAPS_WL}PEM-SERVER-v8}

	openssl req -newkey rsa:4096 -sha256 -new -passin pass:password -passout pass:password -out server-pem.csr <<EOF
US
MA
Bedford
${PEM_BRANDING_COMPANY_NAME_WL}
${PEM_BRANDING_EDB_CAPS_WL} Postgres Manager - HTTPD Server
${PEM_APP_HOST}
${PEM_CERT_EMAIL}
.
.
EOF

	[ -f server-pem.csr ] && openssl req -text -noout -in server-pem.csr

	# Create the Key
	openssl rsa -in privkey.pem -passin pass:password -passout pass:password -out server-pem.key

	# Remove the pass-phrase
	cp server-pem.key server-pem.key.orig
	openssl rsa -in server-pem.key.orig -out server-pem.key

	# Create the Certificate
	openssl x509 -in server-pem.csr -out server-pem.crt -req -sha256 -signkey server-pem.key -days 7300

	# Verify the certificate
	openssl verify server-pem.crt

	rm -f server-pem.csr server-pem.key.orig privkey.pem
	popd > /dev/null
}

ConfigureWebServerConf()
{
	PEM_BACKUP_NUMBER=${TIME_STAMP}
	if [ -f ${WEB_PEM_CONFIG_FILE} ]; then
		Message $MSG_INFO "Taking backup of ${WEB_PEM_CONFIG_FILE}"
		mv ${WEB_PEM_CONFIG_FILE} ${WEB_PEM_CONFIG_FILE}.${PEM_BACKUP_NUMBER}
	fi
	Message ${MSG_INFO} "Creating ${WEB_PEM_CONFIG_FILE}"
	touch ${WEB_PEM_CONFIG_FILE}

	echo "WSGIScriptAlias /pem ${BASE_DIR}/../web/pem.wsgi
WSGIDaemonProcess ${PEM_WEB_SERVER_PROCESS_NAME} processes=1 threads=25 display-name=${PEM_WEB_SERVER_PROCESS_NAME_UPPER} user=pem group=daemon
WSGIProcessGroup ${PEM_WEB_SERVER_PROCESS_NAME}
WSGIScriptReloading On
WSGIPassAuthorization On

<Directory $BASE_DIR/../web>
	SetHandler wsgi-script
	Options +ExecCGI
	WSGIApplicationGroup %{GLOBAL}
	WSGIRestrictProcess  ${PEM_WEB_SERVER_PROCESS_NAME}
	Order deny,allow
	Require all granted
</Directory>

# ReWrite rule for disable the request
<IfModule mod_rewrite.c>
	RewriteEngine on
	RewriteCond %{REQUEST_METHOD} ^(TRACE|TRACK|OPTIONS)
	RewriteRule .* - [F]
</IfModule>
<IfModule mod_headers.c>
        Header unset X-Forwarded-Host
        Header edit Location \"(^http[s]?://)([a-zA-Z0-9\.\-]+)(:\d+)?/\" \"/\"
</IfModule>
<Directory "/usr/share/${WEB_SERVER_NAME}/icons">
    Options -Indexes
</Directory>
ServerSignature Off
ServerTokens Prod" > ${WEB_PEM_CONFIG_FILE}

}

ConfigureWebServerSSLConf()
{
	Message ${MSG_INFO} "Configuring $WEB_SERVER_NAME server sslconf"

	PEM_BACKUP_NUMBER=${TIME_STAMP}
	if [ -f ${WEB_PEM_SSL_CONFIG_FILE} ]; then
		Message ${MSG_INFO} "Taking backup of ${WEB_PEM_SSL_CONFIG_FILE}"
		mv ${WEB_PEM_SSL_CONFIG_FILE} ${WEB_PEM_SSL_CONFIG_FILE}.${PEM_BACKUP_NUMBER}
	fi

	touch ${WEB_PEM_SSL_CONFIG_FILE}

	echo "SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
Listen ${PEM_SERVER_SSL_PORT}
SSLHonorCipherOrder on
SSLPassPhraseDialog  builtin
SSLSessionCache        \"shmcb:/var/log/${WEB_SERVER_NAME}/ssl_scache(512000)\"
SSLSessionCacheTimeout  300

<VirtualHost _default_:${PEM_SERVER_SSL_PORT}>
    #   General setup for the virtual host
    DocumentRoot \"$PEM_BASE_DIR/web\"
    ServerName ${PEM_APP_HOST:=localhost}:${PEM_SERVER_SSL_PORT}
    ServerAdmin you@example.com
    ErrorLog \"/var/log/${WEB_SERVER_NAME}/error_log\"
    TransferLog \"/var/log/${WEB_SERVER_NAME}/access_log\"

    SSLEngine on
    SSLCertificateFile \"${BASE_DIR}/../resources/server-pem.crt\"
    SSLCertificateKeyFile \"${BASE_DIR}/../resources/server-pem.key\"

    <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
        SSLOptions +StdEnvVars
    </FilesMatch>

    <Directory \"/var/www/cgi-bin\">
        SSLOptions +StdEnvVars
    </Directory>

    BrowserMatch \"MSIE [2-5]\" \
        nokeepalive ssl-unclean-shutdown \
        downgrade-1.0 force-response-1.0

    CustomLog \"/var/log/${WEB_SERVER_NAME}/ssl_request_log\" \
        \"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \\\"%r\\\" %b\"
</VirtualHost>

# Only allow TLS v1.2 for security reasons
SSLProtocol -All TLSv1.2
SSLProxyProtocol -All TLSv1.2
SSLCipherSuite HIGH:!aNULL:!MD5
SSLProxyCipherSuite HIGH:!aNULL:!MD5" > ${WEB_PEM_SSL_CONFIG_FILE}

	ConfigureRedirectDefaultWebPort ${WEB_DEFAULT_PORT_CONFIG_FILE}
	InsertWebServerSSLConfModule ${WEB_PEM_SSL_CONFIG_FILE}
}

ConfigureWebServer()
{
	Message ${MSG_INFO} "Configuring ${WEB_SERVER_NAME} server"

	PEM_BACKUP_NUMBER=${TIME_STAMP}

	# Stop web server
	#ExecuteServiceCommand stop ${WEB_SERVER_SERVICE_NAME}
	killall -9 httpd


	if [ -f ${WEB_PEM_WSGI_FILE} ]; then
		Message ${MSG_INFO} "Taking backup of ${WEB_PEM_WSGI_FILE}"
		mv ${WEB_PEM_WSGI_FILE} ${WEB_PEM_WSGI_FILE}.${PEM_BACKUP_NUMBER}
	fi

	Message ${MSG_INFO} "Creating ${WEB_PEM_WSGI_FILE}"
	cp ${WEB_PEM_WSGI_FILE}.in ${WEB_PEM_WSGI_FILE}
	chmod o+r ${WEB_PEM_WSGI_FILE}

	if [ ! -z "${WEB_PEM_CONFIG}" ]; then
		if [ -f ${WEB_PEM_CONFIG} ]; then
			Message ${MSG_INFO} "Taking backup of ${WEB_PEM_CONFIG}"
			mv ${WEB_PEM_CONFIG} ${WEB_PEM_CONFIG}.${PEM_BACKUP_NUMBER}
		fi
	fi

	# Generate hex string for PEM cookie name:
	Message ${MSG_INFO} "Generating PEM Cookie Name."
	SESSION_COOKIE_HEXSTRING=`hexdump -n 4 -e '4/4 "%08X" 1 "\n"' /dev/random | head -c 6`

	Message $MSG_INFO "Creating ${WEB_PEM_PYCONFIG_FILE}"
	touch ${WEB_PEM_PYCONFIG_FILE}
	# Populate the file
	echo "import logging

DEBUG = False
CONSOLE_LOG_LEVEL = logging.WARNING
LOG_FILE = None
PEM_DB_HOST = '${HOST}'
PEM_DB_NAME = 'pem'
PEM_DB_PORT = ${PORT}
SESSION_COOKIE_NAME = 'pem7_session_$SESSION_COOKIE_HEXSTRING'" > ${WEB_PEM_PYCONFIG_FILE}

	if [ ! -z "${PEM_KRB_KTNAME}" ]; then
		echo "

# Use kerberos for authentication
PEM_AUTH_METHOD = 'kerberos'
KRB_APP_HOST_NAME = '${PEM_APP_HOST}'
KRB_KTNAME = '${PEM_KRB_KTNAME}'">> ${WEB_PEM_PYCONFIG_FILE}
	fi
	chmod o+r ${WEB_PEM_PYCONFIG_FILE}

	if [ ! -f $PEM_SERVER_CRT_FILE ]; then
		GenerateSSLCertificateForWebServer
	fi

	# Configure web server
	PEM_SERVER_SSL_PORT=${PEM_SERVER_SSL_PORT:=$(GetWebServerSSLFreePort)}
	SaveInstallConfig PEM_SERVER_SSL_PORT

	ConfigureWebServerConf
	ConfigureWebServerSSLConf
	ConfigureWebServerGNUTLSConf


	Message $MSG_INFO "Executing ${WEB_PEM_SETUP_FILE}"

	# Run setup.py to create pem.db
	su - pem -c "LD_LIBRARY_PATH=${PEM_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH} ${PEM_PYTHON_EXECUTABLE} ${WEB_PEM_SETUP_FILE}"

	Message $MSG_INFO "Check and Configure SELinux security policy for PEM"
	# MSG_LOG_FILE will be passed as arugment to append log in same file
	${PEM_BASE_DIR}/bin/configure-selinux.sh "${MSG_LOG_FILE}"

	# Start web server
	#ExecuteServiceCommand start ${WEB_SERVER_SERVICE_NAME}
	httpd

	Message ${MSG_INFO} "Configured the webservice for ${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager (PEM) Server on port '${PEM_SERVER_SSL_PORT}'."

	# This is required in WEB Mode only
        if [  ${IS_TYPE_WEB} -eq 1 ] && [ ${IS_TYPE_DB} -eq 0 ];  then
                HOST=${DB_HOST}
        fi
	Message ${MSG_INFO} "PEM server can be accessed at https://${HOST}:${PEM_SERVER_SSL_PORT}/pem at your browser"
}

ReplacePlaceHolders()
{
	sed -e "s|$1|$2|g" $3 > "/tmp/$$.tmp"
	mv /tmp/$$.tmp $3
}

ChangePermissionsInDataDirectory()
{
	FILE_PERMISSION="$1"
	FILE_NAME="$2"

	chmod ${FILE_PERMISSION} "${FILE_NAME}"
	chown ${PEM_DB_OS_USER}:${PEM_DB_OS_GROUP} "${FILE_NAME}"
}

GenerateCertificates()
{
	CERT_COMMON_NAME="PEM"
	CERT_COUNTRY="US"
	CERT_STATE="MA"
	CERT_CITY="Bedford"
	CERT_ORG_UNIT="${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager"
	CERT_EMAIL="${PEM_CERT_EMAIL}"

	if [ -f "${PG_DATA_DIR}/ca_key.key" ] && [ -f "${PG_DATA_DIR}/ca_certificate.crt" ]; then
		Message ${MSG_INFO} "Skipping the generating certificates as already present.";
		return;
	fi

	find ${PG_DATA_DIR} \
		-name *.crt -exec bash -c 'mv "$0" "$0.bkup"' {} -o \
		-name *.crl -exec bash -c 'mv "$0" "$0.bkup"' {} -o \
		-name *.key -exec bash -c 'mv "$0" "$0.bkup"' {} \;

	Message $MSG_INFO "Generating certificates."

	# Certificate Authority
	PSQLExecuteSuppressLogVoid "SELECT public.openssl_rsa_generate_key(4096);" "pem" "-X -q" >  "${PG_DATA_DIR}/ca_key.key"
	ChangePermissionsInDataDirectory 0600 "${PG_DATA_DIR}/ca_key.key"

	CA_KEY=$(cat ${PG_DATA_DIR}/ca_key.key)

	PSQLExecuteSuppressLogVoid "SELECT public.openssl_csr_to_crt(public.openssl_rsa_key_to_csr( \
			'${CA_KEY}', '${CERT_COMMON_NAME}', '${CERT_COUNTRY}', \
			'${CERT_STATE}', '${CERT_CITY}', '${CERT_ORG_UNIT}', '${CERT_EMAIL}' \
			), NULL, '${PG_DATA_DIR}/ca_key.key');" "pem" "-X -q" > "${PG_DATA_DIR}/ca_certificate.crt"
	ChangePermissionsInDataDirectory 0600 "${PG_DATA_DIR}/ca_certificate.crt"

	# root
	cp ${PG_DATA_DIR}/ca_certificate.crt ${PG_DATA_DIR}/root.crt
	ChangePermissionsInDataDirectory 0600 "${PG_DATA_DIR}/root.crt"

	PSQLExecuteSuppressLogVoid "SELECT public.openssl_rsa_generate_crl('${PG_DATA_DIR}/ca_certificate.crt', '${PG_DATA_DIR}/ca_key.key');" "pem" "-X -q"  > "${PG_DATA_DIR}/root.crl"
	ChangePermissionsInDataDirectory 0600 "${PG_DATA_DIR}/root.crl"

	# server
	PSQLExecuteSuppressLogVoid "SELECT public.openssl_rsa_generate_key(4096);" "pem" "-X -q" >> "${PG_DATA_DIR}/server.key"
	ChangePermissionsInDataDirectory 0600 "${PG_DATA_DIR}/server.key"

	SSL_KEY=$(cat ${PG_DATA_DIR}/server.key)
	PSQLExecuteSuppressLogVoid "SELECT public.openssl_csr_to_crt(public.openssl_rsa_key_to_csr( \
			'${SSL_KEY}', '${CERT_COMMON_NAME}', '${CERT_COUNTRY}', \
			'${CERT_STATE}', '${CERT_CITY}', '${CERT_ORG_UNIT}', '${CERT_EMAIL}' \
			), NULL, '${PG_DATA_DIR}/ca_key.key');" "pem" "-X -q" > "${PG_DATA_DIR}/server.crt"

	ChangePermissionsInDataDirectory 0600 "${PG_DATA_DIR}/server.crt"
}

GetInstallConfigParameter()
{
	PEM_CONFIG_ARGUMENTS_FILE="${BASE_DIR}/../share/.install-config"
	pattern=$1
	if [ -f ${PEM_CONFIG_ARGUMENTS_FILE} ]; then
		VAL=$(grep "^${pattern}=" ${PEM_CONFIG_ARGUMENTS_FILE})
		if [ ! -z "${VAL}" ]; then
			RET=$(echo $VAL | cut -d '=' -f2)
			echo $RET
		fi
	fi
}

HandleCommandLineArguments()
{
	PYTHON_VERSION=`${PEM_PYTHON_EXECUTABLE} --version 2>&1 | cut -f2 -d' ' | cut -f1,2 -d'.'`

	PYTHON_VERSION_MAJOR=`echo ${PYTHON_VERSION} | cut -f1 -d'.'`
	PYTHON_VERSION_MINOR=`echo ${PYTHON_VERSION} | cut -f2 -d'.'`

	CORRECT_PY_VERSION=0

	if [ "${PYTHON_VERSION_MAJOR}" -ge "2" ]; then
		CORRECT_PY_VERSION=1
		if [ "$PYTHON_VERSION_MINOR" -ge "7" ]; then
			CORRECT_PY_VERSION=1
		fi
	fi

	if [ ${CORRECT_PY_VERSION} = 0 ]; then
		Message ${MSG_CRITICAL} "Python version is not correct. Current version is ${PYTHON_VERSION} while minimum required version is 2.7"
	fi

	# During upgrade mode it will read data from PEM_CONFIG_ARGUMENTS_FILE file
	if [ -f ${PEM_CONFIG_ARGUMENTS_FILE} ]; then
		Message ${MSG_INFO} "Found existing PEM configuration file, running in upgrade mode"
		PEM_INSTALLATION_TYPE=$(GetInstallConfigParameter PEM_INSTALLATION_TYPE)
		PG_INSTALL_PATH=$(GetInstallConfigParameter PG_INSTALL_PATH)
		HOST=$(GetInstallConfigParameter HOST)
		SUPERUSER=$(GetInstallConfigParameter SUPERUSER)
		PORT=$(GetInstallConfigParameter PORT)
		AGENT_CERTIFICATE_PATH=$(GetInstallConfigParameter AGENT_CERTIFICATE_PATH)
		# If it not web mode
		if [ ${PEM_INSTALLATION_TYPE} -ne 2 ]; then
			CIDR_ADDR=$(GetInstallConfigParameter CIDR_ADDR)
			DB_UNIT_FILE=$(GetInstallConfigParameter DB_UNIT_FILE)
		fi
		if [ ${PEM_INSTALLATION_TYPE} -ne 3 ]; then
			PEM_APP_HOST_NAME=$(GetInstallConfigParameter PEM_APP_HOST)

			# Older version PEM may not have the PEM_APP_HOST set
			if [ -z "${PEM_APP_HOST_NAME}" ]; then
				PEM_APP_HOST=${PEM_APP_HOST:=localhost}
			else
				# Allow to override the hostname in upgrade mode too
				PEM_APP_HOST=${PEM_APP_HOST:=${PEM_APP_HOST_NAME}}
			fi
			PEM_SERVER_SSL_PORT_VAL=$(GetInstallConfigParameter PEM_SERVER_SSL_PORT)
			if [ -z "${PEM_SERVER_SSL_PORT_VAL}" ]; then
				PEM_SERVER_SSL_PORT=${DEFAULT_PEM_SERVER_SSL_PORT}
			else
				# Allow to override the web port in upgrade mode too
				PEM_SERVER_SSL_PORT=${PEM_SERVER_SSL_PORT:=${PEM_SERVER_SSL_PORT_VAL}}
			fi
			WEB_PEM_CONFIG=$(GetInstallConfigParameter WEB_PEM_CONFIG)
			WEB_KRB_KTNAME=$(GetInstallConfigParameter PEM_KRB_KTNAME)
			if [ ! -z "${WEB_KRB_KTNAME}" ]; then
				# Allow to override the keytab file path during upgrade
				PEM_KRB_KTNAME=${PEM_KRB_KTNAME:=${WEB_KRB_KTNAME}}
			fi
		fi
	fi

	if [ -z "${PEM_INSTALLATION_TYPE}" ]; then
		ReadValue "${MSG_INPUT_INSTALLATION_TYPE}" PEM_INSTALLATION_TYPE ""
		LogMessageVoid "${MSG_INPUT_INSTALLATION_TYPE} ${PEM_INSTALLATION_TYPE}"
	else
		case ${PEM_INSTALLATION_TYPE} in
			[1]* ) INSTALLATION_TYPE_MSG="1 (Web Services and Database)";;
			[2]* ) INSTALLATION_TYPE_MSG="2 (Web Services)";;
			[3]* ) INSTALLATION_TYPE_MSG="3 (Database)";;
			* ) Message ${MSG_CRITICAL} "Existing Installation type is invalid";;
		esac
		Message ${MSG_INFO} "Existing Installion type ${INSTALLATION_TYPE_MSG} will be used"
	fi

	# This case will be used for fresh installation process.
	case ${PEM_INSTALLATION_TYPE} in
		[1]* ) IS_TYPE_WEB=1; IS_TYPE_DB=1;;
		[2]* ) IS_TYPE_WEB=1; IS_TYPE_DB=0;;
		[3]* ) IS_TYPE_WEB=0; IS_TYPE_DB=1;;
		* ) Message ${MSG_CRITICAL} "Please enter a valid value for installation type (1, 2 or 3).";;
	esac

	# Validate web modules
	if [ "$IS_TYPE_WEB" = "1" ]; then
		PreConfogureWebModWSGIModules
		PreConfigureWebServerSSLModules
		ConfigureWebAddonServices
	fi

	if [ -z "${PG_INSTALL_PATH}" ]; then
		ReadValue "${MSG_INPUT_PG_INSTALL_PATH}" PG_INSTALL_PATH ""
		LogMessageVoid "${MSG_INPUT_PG_INSTALL_PATH} ${PG_INSTALL_PATH}"
	else
		Message ${MSG_INFO} "Existing local database server installation path ${PG_INSTALL_PATH} will be used"
	fi

	if [ -z "${PG_INSTALL_PATH}" ]; then
		Message ${MSG_CRITICAL} "Database server installation path cannot be left empty."
	fi

	if [ ! -f ${PG_INSTALL_PATH}/bin/psql ]; then
		Message ${MSG_CRITICAL} "${MSG_ERROR_PSQL_LIBS_VALIDATE}"
	fi

	if [ ! -f ${PG_INSTALL_PATH}/bin/pg_isready ]; then
		Message ${MSG_CRITICAL} "${MSG_ERROR_PSQL_LIBS_VALIDATE}"
	fi

	# This is required in WEB Mode only
	if [  ${IS_TYPE_WEB} -eq 1 ] && [ ${IS_TYPE_DB} -eq 0 ];  then
		if [ -z "${HOST}" ]; then
			ReadValue "${MSG_INPUT_DB_HOST}" HOST "${DB_HOST}"
		else
			Message ${MSG_INFO} "Existing database server host address ${HOST} will be used"
		fi
	else
		HOST=${DB_HOST}
	fi

	# We need to ask hostname and database port value in any case, otherwise we
	# cannot configure config_local, also Web server configuration will fail.

	if [ -z "${SUPERUSER}" ]; then
		ReadValue "${MSG_INPUT_SUPERUSER}" SUPERUSER ""
		LogMessageVoid "${MSG_INPUT_SUPERUSER} ${SUPERUSER}"
	else
		Message ${MSG_INFO} "Existing database super user name ${SUPERUSER} will be used"
	fi

	if [ -z "${SUPERUSER}" ]; then
		Message ${MSG_CRITICAL} "Database super user name cannot be left empty."
	fi

	if [ -z "${PORT}" ]; then
		ReadValue "${MSG_INPUT_PORT}" PORT ""
		LogMessageVoid "${MSG_INPUT_PORT} ${PORT}"
	else
		Message ${MSG_INFO} "Existing database server port number ${PORT} will be used"
	fi

	if [ -z "${PORT}" ]; then
		Message ${MSG_CRITICAL} "Database server port number cannot be left empty."
	fi

	if [ "${PORT}" -le "1024" ] || [ "${PORT}" -ge "65536" ]; then
		Message ${MSG_CRITICAL} "Port number must be greater than 1024 and less than 65536."
	fi

	if [ -z "${SUPER_PASSWORD}" ]; then
		ReadPassword "${MSG_INPUT_PASSWORD}" SUPER_PASSWORD ""
		LogMessageVoid "${MSG_INPUT_PASSWORD}"
		echo
	fi

	if [ -z "${SUPER_PASSWORD}" ]; then
		Message ${MSG_CRITICAL} "Super user password cannot be left empty."
	fi

	# Set PSQL Enviroment variables
	PSQLEnviromentVariable

	if [ ${IS_TYPE_DB} -eq 1 ]; then
		PEMPSQLEnviromentVariable

		if [ -z "${CIDR_ADDR}" ]; then
			ReadValue "${MSG_INPUT_CIDR_ADDR}" CIDR_ADDR "0.0.0.0/0"
			LogMessageVoid "${MSG_INPUT_CIDR_ADDR} ${CIDR_ADDR}"
		else
			 Message ${MSG_INFO} "Existing CIDR formatted network address range that agents will connect to the server from, to be added to the server's pg_hba.conf file ${CIDR_ADDR} will be used"
		fi

		if [ -z "${DB_UNIT_FILE}" ]; then
			ReadValue "${MSG_INPUT_DB_UNIT_FILE}" DB_UNIT_FILE ""
			LogMessageVoid "${MSG_INPUT_DB_UNIT_FILE} ${DB_UNIT_FILE}"
		else
			Message ${MSG_INFO} "Existing database systemd unit file or init script name ${DB_UNIT_FILE} will be used"
		fi

		if [ -z "$DB_UNIT_FILE" ]; then
                        Message ${MSG_CRITICAL} "Database systemd unit file or init script name cannot be empty"
                else
                        # Check if service exist or not
                        CheckServiceExist ${DB_UNIT_FILE}
                fi
	fi

	if [ -z "${AGENT_CERTIFICATE_PATH}" ]; then
		ReadValue "${MSG_INPUT_AGENT_CERTIFICATE_PATH}" AGENT_CERTIFICATE_PATH "~/.pem/"
		LogMessageVoid "${MSG_INPUT_AGENT_CERTIFICATE_PATH} ${AGENT_CERTIFICATE_PATH}"
	else
		Message ${MSG_INFO} "Existing agent certificate path ${AGENT_CERTIFICATE_PATH} will be used"
	fi

	# Update the installation configuration
	if [ -f "${PEM_CONFIG_ARGUMENTS_FILE}" ]; then
		rm -f "${PEM_CONFIG_ARGUMENTS_FILE}"
	fi

	touch ${PEM_CONFIG_ARGUMENTS_FILE}
	SaveInstallConfig "PEM_INSTALLATION_TYPE"
	SaveInstallConfig "PG_INSTALL_PATH"
	SaveInstallConfig "SUPERUSER"
	SaveInstallConfig "HOST"
	SaveInstallConfig "PORT"
	SaveInstallConfig "AGENT_CERTIFICATE_PATH"

	if [  ${IS_TYPE_WEB} -eq 1 ]; then
		SaveInstallConfig "PEM_PYTHON"
		SaveInstallConfig "PEM_APP_HOST"
		SaveInstallConfig "WEB_PEM_CONFIG" "${WEB_PEM_PYCONFIG_FILE}"
	fi
	if [ ${IS_TYPE_DB} -eq 1 ];  then
		SaveInstallConfig "CIDR_ADDR"
		SaveInstallConfig "DB_UNIT_FILE"
	fi
}

SaveInstallConfig() {
	if [ $# -eq 2 ]; then
		echo ${1}="${2}" >> ${PEM_CONFIG_ARGUMENTS_FILE}
	elif [ $# -eq 1 ]; then
		echo ${1}="${!1}" >> ${PEM_CONFIG_ARGUMENTS_FILE}
	fi
}

InstallPEMServer()
{
	HandleOpensslRndFile
	HandleCommandLineArguments

	# Check Service exist of not for webservice
	if [ ${IS_TYPE_WEB} -eq 1 ]; then
		# Check if service exist or not
		CheckServiceExist ${WEB_SERVER_SERVICE_NAME}

		if [ ! -z "${PEM_KRB_KTNAME}" ]; then
			Message ${MSG_INFO} "Checking for PEM Kerberos ticket (${PEM_KRB_KTNAME})..."

			if [ ! -f ${PEM_KRB_KTNAME} ]; then
				Message ${MSG_CRITICAL} "Kerberos ticket file couldn't be found"
			else
				chown pem "${PEM_KRB_KTNAME}"
				chmod 600 "${PEM_KRB_KTNAME}"
				su - pem -c "touch \"${PEM_KRB_KTNAME}\""

				if [ $? -ne 0 ]; then
					Message ${MSG_CRITICAL} "Kerberos ticket file is not accesible by the pem user"
				fi
				Message ${MSG_INFO} "Configuring PEM web server to use the 'Kerberos' authentication"

        SaveInstallConfig PEM_KRB_KTNAME
			fi
		fi
	fi

	# Attempt to create directory
	if [ ! -d "${AGENT_CERTIFICATE_PATH}" ]; then
		mkdir -p ${AGENT_CERTIFICATE_PATH}
	fi

	if [ -z $PGDATABASE ]; then
		export PGDATABASE=$(GetDBName)
	fi

	# Check SSLUtils is present or not in the specified database before configuring the agent
	CheckSSLUtilsPresent

	if [ ${IS_TYPE_DB} -eq 1 ]; then
		# Configure DB Server
		ConfigureDBServer
	fi

	if [ ${PEM_INSTALLATION_TYPE} -eq 3 ]; then
		export PEMAGENT_DISPLAY_NAME="Postgres Enterprise Manager Database"
	else
		# Web + Database or Web only type:
		export PEMAGENT_DISPLAY_NAME="Postgres Enterprise Manager Host"
	fi

	# Configure PEM Agent
	ConfigurePEMAgent

	# Register DB Server with PEM Agent if is required
	if [ "${REQUIRED_REGISTER_SERVER_WITH_PEM}" = "yes" ]; then
		RegisterServerWithPEM
	fi
	Message ${MSG_INFO} "Enable pemagent service."
	# Enable PEM Agent Service
	#ExecuteServiceCommand enable ${AGENT_SERVICE_NAME} "ignore"

	Message $MSG_INFO "Stop pemagent service"
	# Stop PEM Agent Service if any instance running - upgrade mode.
	#ExecuteServiceCommand stop ${AGENT_SERVICE_NAME} "ignore"
	killall -9 pemagent pemworker

	Message $MSG_INFO "Start pemagent service."
	# Start PEM Agent Service
	#ExecuteServiceCommand start ${AGENT_SERVICE_NAME}
	/usr/edb/pem/agent/bin/pemagent -c /usr/edb/pem/agent/etc/agent.cfg

	if [ ${IS_TYPE_WEB} -eq 1 ]; then
		# ConfigureWebServer when pem.wsgi does not exist - fresh installation
		if [ ! -f ${BASE_DIR}/../web/pem.wsgi ]; then
			# Configure web Server
			ConfigureWebServer
		else
			# Its upgrade mode
			# If pem.wsgi exist and contain venv that means its 7.6+ so no need to create again
			# But if it do not contain venv that its mean its older version to 7.6 upgrade - onetime we need to recreate
			ifvenvExist=$(grep -c "venv" ${BASE_DIR}/../web/pem.wsgi)
			if [ ${ifvenvExist} -eq 0 ]; then
				# Does not contain venv so reConfigure Web Server
				ConfigureWebServer
			fi
		fi
	fi
}

UninstallPEMServer()
{
	if [ -z "${PG_INSTALL_PATH}" ]; then
		ReadValue "Enter database server installation path:" PG_INSTALL_PATH ""
	fi

	if [ -z "${PG_INSTALL_PATH}" ]; then
		Message ${MSG_CRITICAL} "Database server installation path cannot be left empty."
	elif [ ! -f ${PG_INSTALL_PATH}/bin/psql ]; then
		Message ${MSG_CRITICAL} "Database server installation path is not correct."
	fi

	if [ -z "${PORT}" ]; then
		ReadValue "Enter database server port number:" PORT ""
	fi

	if [ "${PORT}" -le "1024" ] || [ "${PORT}" -ge "65536" ]; then
		Message $MSG_CRITICAL "Port number must be greater than 1024 and less than 65536."
	fi

	if [ -z "${SUPERUSER}" ]; then
		ReadValue "Enter database super user name (${PEM_DB_SUPERUSER}, postgres, etc.): " SUPERUSER ""
	fi

	if [ -z "${SUPERUSER}" ]; then
		Message ${MSG_CRITICAL} "Database super user name cannot be left empty."
	fi

	if [ -z "${SUPER_PASSWORD}" ]; then
		ReadPassword "Enter database super user password:" SUPER_PASSWORD ""
	fi

	if [ -z "${SUPER_PASSWORD}" ]; then
		Message ${MSG_CRITICAL} "Super user password cannot be left empty."
	fi

	# Stop web server
	Message ${MSG_INFO} "Stop ${WEB_SERVER_SERVICE_NAME} service."
	#ExecuteServiceCommand stop $WEB_SERVER_SERVICE_NAME
	killall -9 httpd

	# Stop pemagent service
	Message ${MSG_INFO} "Stop ${AGENT_SERVICE_NAME} service."
	#ExecuteServiceCommand stop ${AGENT_SERVICE_NAME}
	killall -9 pemagent pemworker

	# Set PSQL Enviroment variables
	PSQLEnviromentVariable
	PSQLExecuteCMD "UPDATE pem.server SET active = 'f' WHERE id = 1;" "pem"
	PSQLExecuteCMD "DROP EXTENSION IF EXISTS sslutils;" "pem"

	UninstallWebServerModules

	if [ -f ${WEB_PEM_PYCONFIG_FILE} ]; then
		rm -rf ${WEB_PEM_PYCONFIG_FILE}
	fi

	if [ -f ${WEB_PEM_WSGI_FILE} ]; then
		rm -rf {WEB_PEM_WSGI_FILE}
	fi

	if [ -d ${BASE_DIR}/../web/__pycache__ ]; then
		rm -rf ${BASE_DIR}/../web/__pycache__
	fi

	Message ${MSG_INFO} "Start ${WEB_SERVER_SERVICE_NAME} service."
	# Start web server
	ExecuteServiceCommand start ${WEB_SERVER_SERVICE_NAME}
	httpd

	Message ${MSG_INFO} "Disable ${AGENT_SERVICE_NAME} service."
	# Disable pemgent service
	#ExecuteServiceCommand disable ${AGENT_SERVICE_NAME}

}

#------------------
# User Inputs #
#------------------

MessageHeading "${PEM_BRANDING_EDB_CAPS_WL} Postgres Enterprise Manager"

#---------------------------------
# Process command line arguments #
#---------------------------------

while [ $# -ne 0 ];
do
	RAR_NO_PROCD_CMD=0
	ProcessCommandLine $*
	INDEX=0
	while [ "${INDEX}" != "${RAR_NO_PROCD_CMD}" ]; do
		shift
		INDEX=`expr ${INDEX} + 1`
	done
done

# TODO: Check whether this part exists in the spec file or not
# Initialize the default value
if [ ${AGENT_SERVICE_NAME_PROVIDED} -eq 0 ]; then
	AGENT_SERVICE_NAME=pemagent
	AGENT_SERVICE_NAME_PROVIDED=1
fi

# -----------------------------
# Main
# -----------------------------

if [ ${UNINSTALL_PEM_SERVER_PROVIDED} -eq 1 ]; then
	# Uninstall PEM Server
	UninstallPEMServer

	# Terminate the script
	exit
fi

################################
# Packages required
# yum -y install mod_ssl mod_wsgi
################################

# --------------------------------
# Get input values
# --------------------------------

if [ ${UNINSTALL_PEM_SERVER_PROVIDED} -eq 0 ]; then
	# Install PEM Server
	InstallPEMServer
fi
