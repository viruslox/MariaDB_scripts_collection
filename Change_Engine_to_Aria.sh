#!/bin/bash

MYSQLCONNECT=$(which mysql)
MYSQLANALYZE=$(which mysqlanalyze) 
MYSQLREPAIR=$(which mysqlrepair)
MYSQLOPTIMIZE=$(which mysqloptimize)
echo -n "Please give Your database user name: "
read MYSQL_USER
echo -n "Please give Your database user $MYSQL_USER password: "
read -s MYSQL_PASSWORD
printf "\n"
echo -n "Please give Your database name: "
read DATABASE

for mycomm in $MYSQLCONNECT $MYSQLANALYZE $MYSQLREPAIR $MYSQLOPTIMIZE ; do
  if [[ ! -x "$mycomm" ]]; then
    echo "Error: $mycomm command not found."
    exit 1
  fi
done

"$MYSQLCONNECT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -A -D "$DATABASE" -e "select 1" $1 > /dev/null
if [ "$?" -eq 0 ]; then
    echo "Connection to database available"
else
    echo "Connection to database failed, check provided credentials"
	exit 1
fi

# Get table names 
TABLES=()
while IFS= read -r TABLE; do
  TABLES+=("$TABLE")
done < <("$MYSQLCONNECT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -A -D "$DATABASE" -N -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DATABASE' AND TABLE_TYPE='BASE TABLE'")

for TABLE in "${TABLES[@]}"; do
  echo "Altering Table : $TABLE"
  "$MYSQLCONNECT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$DATABASE" -N -e "ALTER TABLE \`$TABLE\` ENGINE=Aria"
	if [ "$?" -ne 0 ]; then
		echo "Error altering table $TABLE: $?"
	fi
done

mysqlanalyze -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE"
mysqlrepair -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE"
mysqloptimize -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE"

echo "Job done"

exit 0
