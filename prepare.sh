#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi
# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Navigate to the script's directory
cd "$SCRIPT_DIR" || exit
source ./.env
architecture=$(uname -m)
passwordLength=18
if [ "$architecture" == "x86_64" ]; then
  MYSQL_IMAGE="mysql:8.0.37-debian"
else
  MYSQL_IMAGE="mysql:8.0.37"
fi
#if MYSQL_PORT is not set then set it to 3306
if [ -z "$MYSQL_PORT" ]; then
  MYSQL_PORT=127.0.0.1:3306
fi
#if PHPMYADMIN_PORT is not set then set it to 8801
if [ -z "$PHPMYADMIN_PORT" ]; then
  PHPMYADMIN_PORT=8801
fi



chmod +x *.sh
echo "MYSQL_IMAGE=$MYSQL_IMAGE" > .env
echo "MYSQL_PORT=$MYSQL_PORT" >> .env
echo "PHPMYADMIN_PORT=$PHPMYADMIN_PORT" >> .env

if [ ! -f mysql.env ]; then
  echo "mysql.env not found, copying from mysql.env.example"
  cp mysql.env.example mysql.env
  echo "Generate random password for MYSQL_ROOT_PASSWORD"
  root_password=$(< /dev/urandom tr -dc '[:upper:]' | head -c 1)$(< /dev/urandom tr -dc '[:lower:]' | head -c 1)$(< /dev/urandom tr -dc '0-9' | head -c 1)$(< /dev/urandom tr -dc '[:alnum:]' | head -c "$((passwordLength - 3))"; echo)
  sed -i "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=\"$root_password\"/" mysql.env
  #update mysql root host
  #read docker-compose.yml file for root host
  root_host=$(grep -oP '(?<=subnet: ).*' docker-compose.yml | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | awk -F. '{print $1"."$2"."$3".%"}')
  sed -i "s/MYSQL_ROOT_HOST=.*/MYSQL_ROOT_HOST=\"$root_host\"/" mysql.env


fi

mkdir -p mysql/data
mkdir -p mysql/log
# Check if data and log dir empty or not if not empty then try to empty it with confirmation
if [ "$(ls -A mysql/data)" ]; then
    read -p "mysql/data is not empty, do you want to empty it? (y/n) " -r

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        docker compose down
        rm -rf mysql/data/*
        rm -rf mysql/log/*
    else
        echo "Keep existing data"
    fi
fi

chown -R 999:999 mysql/data
chown -R 999:999 mysql/log
echo "Mysql is ready. Run 'docker compose up -d' to start the mysql server"


