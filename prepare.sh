#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi
# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Navigate to the script's directory
cd "$SCRIPT_DIR" || exit
# Load environment variables
if [ -f .env ]; then
  source ./.env
fi
# Check if docker-compose.yml exists, if not copy from docker-compose-sample.yml
if [ ! -f docker-compose.yml ]; then
  cp docker-compose-sample.yml docker-compose.yml
fi
architecture=$(uname -m)
passwordLength=18
if [ "$architecture" == "x86_64" ]; then
  MYSQL_IMAGE="mysql:8.0.37-debian"
else
  MYSQL_IMAGE="mysql:8.0.37"
fi
echo "MYSQL_IMAGE=$MYSQL_IMAGE" > .env

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
docker compose up -d
echo "Mysql is ready"
echo "Root password: $root_password"


