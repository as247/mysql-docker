#!/bin/bash
#switch to bash if run by sh
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi
# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Navigate to the script's directory
cd "$SCRIPT_DIR" || exit

if [ ! -f mysql.env ]; then
  echo "mysql.env not found"
  exit 1
fi
root_password=""
source ./env.sh
restore_file=""
dbName=""
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: restore.sh <db> <backup_file>"
  exit 1
else
  restore_file="$1"
  dbName="$2"
fi
if [ ! -f "$restore_file" ]; then
  echo "File $restore_file not found"
  exit 1
fi
echo "Restore $restore_file"
#drop all tables
echo "Drop all tables"
dropTables_file="mysql/helpers/droptables.sql"
docker compose exec -T db mysql -u root -p"$root_password" "$dbName" < "$dropTables_file"
echo "Restoring"
#check if file is gzip
if [[ "$restore_file" == *.gz ]]; then
  gunzip -c "$restore_file" | docker compose exec -T db mysql -u root -p"$root_password" "$dbName"
else
  docker compose exec -T db mysql -u root -p"$root_password" "$dbName" < "$restore_file"
fi
echo "Restore done"