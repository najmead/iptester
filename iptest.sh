#!/bin/bash

email="yourmail@email.com"
domain="yourdomain.com"

## Initialise

command -v dig >/dev/null 2>&1 || { echo >&2 "[ERROR]: I require dig but it's not installed.  Aborting."; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo >&2 "[ERROR]: I require sqlite3 but it's not installed.  Aborting."; exit 1; }

if [ ! -e iphistory.db ];
then
	echo "[INFO]: Initialising database"
	create="create table iptest (ID integer primary key, TestTime text, IP text);"
	sqlite3 iphistory.db "${create}"
fi

## Run test

myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
testdate=$(date +"%Y-%m-%d %T")
echo "[INFO]: Found IP address $myip. Logging it for future reference."

insert="insert into iptest (TestTime, IP) values ('$testdate', '$myip');"
sqlite3 iphistory.db "${insert}"

## Perform comparison

query="select count(distinct IP) from iptest where TestTime in (select TestTime from iptest order by TestTime desc limit 0,2);"
difftest=$(sqlite3 iphistory.db "${query}")

if [ $difftest -ne 1 ];
then
	msg="[WARNING]: IP Address has changed since last run.  New IP is ${myip}"
	echo $msg
	mail -s "[${domain}]: IP Address Update" $email <<< $msg
fi

