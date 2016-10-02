#!/bin/sh

# README 
#
# This script should run in the same directory where your downloaded txt files are placed.
#
# If mariadb is not installed, then follow this steps:
# 1) Using root or with sudo, install mariadb client and database.
#    dnf install mariadb mariadb-server
#
# 2) Start db engine
#    systemctl start mariadb
#
# 3) configure tour installation (define db root password and accept all others default options)
#    mysql_secure_installation
#
# 4) set this  script variable ( db user and db password)
#
# 5) run this script
#

# MariaDB user and password
#MARIADBUSER=root
#MARIADBPASSWORD=P4ssw0rd

# Read config.sh: Configuration file 

WORKDIR=`dirname $0`
CONFIG_FILE=$WORKDIR/config.sh
[ -f $CONFIG_FILE ] && source $CONFIG_FILE


#CREATE TABLE passwordhash (
#    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
#    userid VARCHAR(8) NOT NULL,
#    password CHAR(40),
#    CONSTRAINT \`fk_user_password\`
#        FOREIGN KEY (userid) REFERENCES idemail (id)
#        ON DELETE CASCADE
#        ON UPDATE RESTRICT
#) ENGINE = InnoDB;

# Database Schema

SQL="
DROP DATABASE IF EXISTS lnkin;
CREATE DATABASE lnkin;

USE lnkin;
CREATE TABLE idemail (
    MEMBER_ID VARCHAR(255) NOT NULL PRIMARY KEY,
    MEMBER_PRIMARY_EMAIL VARCHAR(255)
) ENGINE = MyISAM;

CREATE TABLE passwordhash (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    userid INT NOT NULL,
    password VARCHAR(255),
    INDEX userid_idx (userid)
) ENGINE = MyISAM;
"

SQLTRANSFORM="
USE lnkin;

ALTER TABLE idemail DROP PRIMARY KEY;
ALTER TABLE idemail CHANGE MEMBER_ID MEMBER_ID int;
CREATE INDEX MEMBER_ID_IDX ON idemail (MEMBER_ID);
CREATE INDEX MEMBER_PRIMARY_EMAIL_IDX ON idemail (MEMBER_PRIMARY_EMAIL);

CREATE VIEW users AS 
    SELECT idemail.MEMBER_PRIMARY_EMAIL AS username, passwordhash.password AS password FROM
        idemail INNER JOIN passwordhash ON idemail.MEMBER_ID = passwordhash.userid; 

"

#############################################
#
# Function definitions
#
#############################################

#LOGFILE=import.log.txt 

print_log_header() {
    echo -e "+--------------------+------------+----------+" >  $LOGFILE
    echo -e "|     COMMAND        |    DATE    |   TIME   |" >> $LOGFILE
    echo -e "+--------------------+------------+----------+" >> $LOGFILE
}

print_log_row() {
    echo -e "| $1   | $2 | $3 |" >> $LOGFILE
    echo -e "+--------------------+------------+----------+" >> $LOGFILE
}

#############################################
#
# Main
#
#############################################

clear
print_log_header
print_log_row "START Process   " `date +%Y-%m-%d` `date +%H:%M:%S`
echo -e "Building Database structure for lnkin ... \n" 

# Build database structure
print_log_row "Init DB Struct  " `date +%Y-%m-%d` `date +%H:%M:%S`
mysql -u$MARIADBUSER -p$MARIADBPASSWORD -e "$SQL"


# Insert into MariaDB all user email IDs 

echo -e "Importing email ids ... \n"
print_log_row "Import email ids" `date +%Y-%m-%d` `date +%H:%M:%S`
mysql -Dlnkin -u$MARIADBUSER -p$MARIADBPASSWORD < 1.sql.txt 

# Alter column MEMBER_ID to integer to increase performance
echo -e "Transforming table... \n"
print_log_row "Table Transform " `date +%Y-%m-%d` `date +%H:%M:%S`
mysql -u$MARIADBUSER -p$MARIADBPASSWORD -e "$SQLTRANSFORM"


FILES="1.txt 2.txt 3.txt
4.txt 5.txt 6.txt 7.txt 8.txt 9.txt"

for f in $FILES
do
    echo -e "Importing password File: $f \n"
    print_log_row "Import "$f"    " `date +%Y-%m-%d` `date +%H:%M:%S`
#   Convert from dos format, build sql string and run into MariaDB
    tr -d '\r' < $f | awk -F ":" '{print "insert into passwordhash(userid,password) values (" $1 ",'\''" $2 "'\'');"; }' | mysql -Dlnkin -u$MARIADBUSER -p$MARIADBPASSWORD
done

print_log_row "Finish process  " `date +%Y-%m-%d` `date +%H:%M:%S`
