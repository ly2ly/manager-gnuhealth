#!/bin/bash

# Copyright 2018, APSARL
# License MIT.

# manage-gnuhealth.sh is a tool to manage your GUNHEALTH installation.
# You can create, update, drop, backup or restore databases easily
# Must be execute as root

# To do: Log and error management

# Note:
# psql -h example.com -U backup -t -A -c 'SELECT datname FROM pg_database where datname not in ('template0', 'template1', 'postgres')'
# psql -h localhost -U gnuhealth -t -A -c 'SELECT datname FROM pg_database where Owner is gnuhealth'

### First Set up your local Variable!

## ADMIN PARAMETERS
# Path to trytond-admin file of your server 
TRYTON_ADM='/home/gnuhealth/gnuhealth/tryton/server/trytond-4.2.6/bin/trytond-admin'
# Path to trytond conf file
TRYTON_CONF='/home/gnuhealth/gnuhealth/tryton/server/config/trytond.conf'
# Folder where you have all tryton modules
TRYTON_MODULES='/home/gnuhealth/gnuhealth/tryton/server/modules/*'
# User who own gnuhealth right
TRYTON_USER='gnuhealth'
# Database role
DB_ROLE='gnuhealth'

## SAVE PARAMETERS
# Folder of the save (must be owned by postgres:gnuhealth)
SAVE_DIR='/home/gnuhealth/backup'
# Timestamp of the database save
DATE_SAVE=`date +%Y-%m-%d`
# Save extension
FILE_EXT='.backup'


# Little menu to choose the different options
echo "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Welcome to GNU HEALTH Manager! With this command line tool you can manage
your GNU HEALTH installation.
You can create, update, drop, backup or restore databases easily.
The server will be stopped during operations and it will be restarted
at the end.
Choose your action with 1, 2, 3, 4, 5 or 6 and follow instructions:
1 - Create a new GNU Health database
You will create a new empty database with all modules updated
ready for install.

2 - Install all modules and update an existing database
You will install all modules of the module folder and update selected
database.

3 - Drop an existing database
You will drop an existing database.

4 - Backup an existing database
You will backup an existing database in the save directory.

5 - Restore a backup database for GNU Health
You will restore a backup database previously saved in the save directory.

6 - Duplicate a database
You will make a duplicate of an existing database
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
"


read ACTION

# Clause for 1 statement: Create a new GNU Health database
if [ ${ACTION} -eq 1 ]; then

# Input the database name!
# TO DO: Verify if database already exist and tell if
# TO DO: Verify that there don't have space in the name
	echo "
	GNU HEALTH Manager: 1 - Create a new GNU Health database
	You will create a new empty database with all modules updated
	and ready for configuration.

	Give database name! (with no spaces and special characters please...).
	Database name must be unique.
	"
	read CREATE_DB_NAME

# Stop tryton server
	echo "GNU HEALTH Manager: Stop tryton server"
	service tryton-server stop
	
# Creation of the database
	echo "GNU HEALTH Manager: We create Database ${CREATE_DB_NAME}!"
	su - postgres -c "createdb --encoding=UNICODE --owner=$TRYTON_USER  ${CREATE_DB_NAME}"

# Installation of tryton modules
	echo "GNU HEALTH Manager: We install all modules of the folder"
	for file in ${TRYTON_MODULES}
	do
	if [ -d "${file}" ]
	then
		echo "GNU HEALTH Manager: Install ${file} with pip" 
		su - ${TRYTON_USER} -c "pip3 install ${file}"
	fi
	done

# Configuration of the database
	echo "GNU HEALTH Manager: We configure Database ${CREATE_DB_NAME}!"
	su - ${TRYTON_USER} -c "python3 ${TRYTON_ADM} -c ${TRYTON_CONF} -d ${CREATE_DB_NAME} --all -v -p"

# Start tryton server
	echo "GNU HEALTH Manager: Start tryton server"
	service tryton-server start

# Clause for 2 statement: Install all modules and update an existing database
elif [ ${ACTION} -eq 2 ]; then

# Input the database name!
# TO DO: Verify if database not exist and tell if
	echo "
	GNU HEALTH Manager: 2 - Install all modules and update an existing database
	You will install all modules of the module folder and update selected
	database.

	Give database name to update!(with no spaces and special characters please...)
	Database must exist.
	"
	read UPDATE_DB_NAME

# Stop tryton service
	echo "GNU HEALTH Manager: Stop tryton server"
	service tryton-server stop
	
# Installation of tryton modules
	echo "GNU HEALTH Manager: We install all modules"
	for file in ${TRYTON_MODULES}
	do
	if [ -d "${file}" ]
	then
		echo "GNU HEALTH Manager: Install ${file} with pip" 
		su - ${TRYTON_USER} -c "pip3 install ${file}"
	fi
	done

# Configuration of the database
	echo "GNU HEALTH Manager: We configure Database!"
	su - ${TRYTON_USER} -c "python3 ${TRYTON_ADM} -c ${TRYTON_CONF} -d ${UPDATE_DB_NAME} --all -v -p"

# Start tryton service
	echo "GNU HEALTH Manager: Start tryton server"
	service tryton-server start	
	
# Clause for 3 statement: Drop an existing database
elif [ ${ACTION} -eq 3 ]; then	

# Input the database name!
# TO DO: Verify if database not exist and tell if
	echo "
	GNU HEALTH Manager: 3 - Drop an existing database
	You will drop an existing database.

	Give database name to DROP!(with no spaces and special characters please...)
	Database must exist.
	"
	read DROP_DB_NAME

# Stop tryton server 
	echo "GNU HEALTH Manager: Stop tryton server"
	service tryton-server stop
		
# Avertize before droping and dropping
	echo "GNU HEALTH Manager: ARE YOU SURE? YOU WANT TO DROP db_name??? (Y/N)"
	read DROP_OPTION

	if [ ${DROP_OPTION} == "Y" ] || [ ${DROP_OPTION} == "y" ]; then
		echo "GNU HEALTH Manager: We drop ${DROP_DB_NAME}"
		su - postgres -c "dropdb ${DROP_DB_NAME}"
		echo "GNU HEALTH Manager: Database ${DROP_DB_NAME} is dropped!"
	else
		echo "GNU HEALTH Manager: You don't give Y so drop ${DROP_DB_NAME} is cancelled!"
	fi

# Start tryton server
	echo "GNU HEALTH Manager: Start tryton server"
	service tryton-server start


# Clause for 4 statement: Backup an existing database
elif [ ${ACTION} -eq 4 ]; then	

# Input the database name to save!
# TO DO: Verify if database already exist and tell if
	echo "
	GNU HEALTH Manager: 4 - Backup an existing database
	You will backup an existing database in the save directory.

	Give database name to save!(with no spaces and special characters please...)
	Database must exist.
	"
	read DB_SAVE_NAME	

# Stop tryton server
	echo "GNU HEALTH Manager: Stop tryton server"
	service tryton-server stop
	
# Save of the database
	echo "GNU HEALTH Manager: Save of the database GNU HEALTH ${DB_SAVE_NAME}, please wait..."
	su - postgres -c "pg_dump --verbose --role ${DB_ROLE} --format t --blobs --file ${SAVE_DIR}'/'${DB_SAVE_NAME}'_DBSAVE_'${DATE_SAVE}${FILE_EXT} ${DB_SAVE_NAME}"
	echo "GNU HEALTH Manager: Database save completed"
	
# Start tryton server
	echo "GNU HEALTH Manager: Start tryton server"
	service tryton-server start


# Clause for 5 statement: Restore a dump database for GNU Health
elif [ ${ACTION} -eq 5 ]; then	
	
# Input the database name to restore and new database name!
# TO DO: Verify if databases already exist or not and tell if
	echo "
	GNU HEALTH Manager: 5 - Restore a backup database for GNU Health
	You will restore a backup database previously saved in the save directory.

	Give name of the file to restore!(with no spaces and special characters please...)
	Give all name with extention.
	"
	read DB_RESTORE_NAME			

# Input the name of the database used for restore!	
	echo "GNU HEALTH Manager: Give name of the new database!(with no spaces and special characters please...)"
	read NEW_DB_NAME		

# Stop tryton server 
	echo "GNU HEALTH Manager: Stop tryton server"
	service tryton-server stop
	
# Create empty database
	echo "GNU HEALTH Manager: Create empty database ${NEW_DB_NAME}"
	su - postgres -c "createdb --owner ${DB_ROLE} ${NEW_DB_NAME}"
	
# Restore the database
	echo "GNU HEALTH Manager: Restore the database ${DB_RESTORE_NAME} inside ${NEW_DB_NAME}"
	su - postgres -c "pg_restore --verbose --create --role ${DB_ROLE} --dbname ${NEW_DB_NAME} ${SAVE_DIR}'/'${DB_RESTORE_NAME}"
	
# Configuration of the database
	echo "GNU HEALTH Manager: We configure Database ${NEW_DB_NAME}!"
	su - ${TRYTON_USER} -c "python3 ${TRYTON_ADM} -c ${TRYTON_CONF} -d ${NEW_DB_NAME} --all -v -p"
	
# Start tryton server
	echo "GNU HEALTH Manager: Start tryton server"
	service tryton-server start

# Clause for 6 statement: Duplicate a database
elif [ ${ACTION} -eq 6 ]; then	

# Input the database name to duplicate!
	echo "
	GNU HEALTH Manager: 6 - Duplicate a database
	You will make a duplicate of an existing database

	Give database name to duplicate!(with no spaces and special characters please...)
	Database must exist.
	"
	read DB_DUPLICATE_NAME	
	
# Input the new database name!
	echo "GNU HEALTH Manager: Give the new database name!(with no spaces and special characters please...)
	Database name must be unique."
	read DB_COPY_NAME	

# Stop tryton server
	echo "GNU HEALTH Manager: Stop tryton server"
	service tryton-server stop
	
# Sauvegarde de la base de donnée TEMP
	echo "GNU HEALTH Manager: TEMP Save of ${DB_DUPLICATE_NAME}"
	su - postgres -c "pg_dump --verbose --role ${DB_ROLE} --format t --blobs --file ${SAVE_DIR}'/'${DB_DUPLICATE_NAME}'_TEMP'${FILE_EXT} ${DB_DUPLICATE_NAME}"

# Create empty database for copy	
	echo "GNU HEALTH Manager: Create ${DB_COPY_NAME} empty database for copy"
	su - postgres -c "createdb --owner ${DB_ROLE} ${DB_COPY_NAME}"	

# Restore the dumped database
	echo "GNU HEALTH Manager: Restore the dumped database ${DB_DUPLICATE_NAME} inside ${DB_COPY_NAME}"
	su - postgres -c "pg_restore --verbose --create --role ${DB_ROLE} --dbname ${DB_COPY_NAME} ${SAVE_DIR}'/'${DB_DUPLICATE_NAME}'_TEMP'${FILE_EXT}"

# Configuration of the new database
	echo "GNU HEALTH Manager: We configure new Database ${DB_COPY_NAME}!"
	su - ${TRYTON_USER} -c "python3 ${TRYTON_ADM} -c ${TRYTON_CONF} -d ${DB_COPY_NAME} --all -v -p"
	
# Remove TEMP save	
	echo "GNU HEALTH Manager: Remove TEMP save"
	rm ${SAVE_DIR}'/'${DB_DUPLICATE_NAME}'_TEMP'${FILE_EXT}

# Start tryton server
	echo "GNU HEALTH Manager: Start tryton server"
	service tryton-server start

else echo "GNU HEALTH Manager: You must enter integer like '1'. Action is cancelled, restart"
fi
