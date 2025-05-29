#!/bin/bash

echo "⚠️  Database Reset Script ⚠️"
echo "This script will reset your database environment."

# Check for backup
read -p "Remember to backup your database using backup_galera.sh. Do you want to proceed? (yes/no): " proceed
if [ "$proceed" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Check and stop running containers
if [ $(docker compose ps | grep -q "mariadb") ]; then
    echo "Stopping MariaDB container..."
    docker compose down
fi

# Check for and handle old container deletion
old_container=$(docker ps -a | grep "mariadb:lts-noble" | awk '{print $1}')
if [ ! -z "$old_container" ]; then
    echo "Found existing MariaDB container: $old_container"
    read -p "Do you want to delete the old mariadb:lts-noble container? (Recommended) (yes/no): " delete_container
    if [ "$delete_container" = "yes" ]; then
        echo "Removing MariaDB container..."
        docker rm -f $old_container
    fi
else
    echo "No existing MariaDB container found."
fi

# Delete and recreate data directory
echo "Removing old data directory..."
sudo rm -rf ./data
echo "Creating new data directory..."
mkdir -p ./data
sudo chown 999:999 ./data

# Check current bootstrap setting and ask about changing it
if [ -f galera.cnf ]; then
    current_setting=$(grep -o 'wsrep_new_cluster=\(ON\|OFF\)' galera.cnf || echo "wsrep_new_cluster not found")
    echo "Current setting in galera.cnf: $current_setting"
    
    read -p "Should this database bootstrap a new cluster? (yes/no): " bootstrap
    if [ "$bootstrap" = "yes" ] && [ "$current_setting" = "wsrep_new_cluster=OFF" ]; then
        echo "Setting wsrep_new_cluster=ON in galera.cnf..."
        sed -i 's/wsrep_new_cluster=OFF/wsrep_new_cluster=ON/' galera.cnf
    elif [ "$bootstrap" = "no" ] && [ "$current_setting" = "wsrep_new_cluster=ON" ]; then
        echo "Setting wsrep_new_cluster=OFF in galera.cnf..."
        sed -i 's/wsrep_new_cluster=ON/wsrep_new_cluster=OFF/' galera.cnf
    else
        echo "No change needed in galera.cnf"
    fi
else
    echo "Warning: galera.cnf not found!"
    exit 1
fi

# Ask about starting container
read -p "Do you want to start the database container now? (yes/no): " start_container
if [ "$start_container" = "yes" ]; then
    echo "Starting MariaDB container..."
    docker compose up -d
    echo -e "\n✅ Container started!"
    echo "To check if the container is running, use:"
    echo "  docker compose ps"
    echo "To check the logs, use:"
    echo "  docker compose logs -f"
    echo "To check if MariaDB is ready, use:"
    echo "  docker compose exec mariadb mysqladmin ping -h localhost"
else
    echo -e "\n✅ Setup complete! To start the container later, run:"
    echo "  docker compose up -d"
fi
