# 💾 MariaDB Galera Cluster with Docker Compose

[![Static Badge](https://img.shields.io/badge/Docker-Compose-white?style=flat&logo=docker&logoColor=white&logoSize=auto&labelColor=black)](https://docker.com/)
[![Static Badge](https://img.shields.io/badge/MariaDB-Galera-white?style=flat&logo=mariaDB&logoColor=white&logoSize=auto&labelColor=black)](https://docker.com/)
[![Static Badge](https://img.shields.io/badge/Linux-white?style=flat&logo=linux&logoColor=white&logoSize=auto&labelColor=black)](https://www.linux.org/)
[![Static Badge](https://img.shields.io/badge/GPL-V3-white?style=flat&logo=gnu&logoColor=white&logoSize=auto&labelColor=black)](https://www.gnu.org/licenses/gpl-3.0.en.html/)

A MariaDB Galera Cluster setup using Docker Compose.

## ✨ Features

- Multi-node MariaDB Galera Cluster
- Automatic node synchronization
- Built-in health monitoring
- Environment-based configuration
- Persistent data storage
- Custom Galera configuration
- Database reset script
- Database backup script

## 🚀 Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/peterweissdk/galera-compose.git
   cd galera-compose
   ```

2. Configure your environment variables:
   ```bash
   # Edit .env with your desired settings
   ```

3. Configure the Galera cluster settings in galera.cnf
   ```bash
   # Edit galera.cnf and set
   wsrep_new_cluster=ON  # Set to ON for the first node only
   ```

4. Create data directory with correct permissions:
   ```bash
   mkdir data
   sudo chown 999:999 data
   ```

5. Start the cluster:
   ```bash
   docker compose up -d
   ```

6. After the first node is running, set `wsrep_new_cluster=OFF` and start additional nodes:
   ```bash
   # Edit galera.cnf and set
   wsrep_new_cluster=OFF  # Set back to OFF after cluster is bootstrapped
   ```

> **Note**: The `wsrep_new_cluster` setting is only needed ON for bootstrapping the first node at first boot up sequence. All subsequent nodes should have it set to OFF.
If you bring the cluster back up after a crash, you will need to set `wsrep_new_cluster=ON` at the first boot up sequence to allow the cluster to rejoin. Then bring the joining nodes up one at the time.
## 🔧 Configuration

### Environment Variables
- `MYSQL_ROOT_PASSWORD`: Root password for MariaDB
- `MYSQL_DATABASE`: Name of the default database to create
- `MYSQL_USER`: Username for the default database
- `MYSQL_PASSWORD`: Password for the default user

### Galera Configuration
Key settings in `galera.cnf`:
- `wsrep_cluster_name`: Name of your Galera cluster
- `wsrep_cluster_address`: List of cluster nodes
- `wsrep_node_name`: Unique name for each node
- `wsrep_node_address`: IP address of the node
- `wsrep_new_cluster`: Enables bootstrapping a new cluster

## 📝 Directory Structure

```
galera-compose/
├── data/                # Persistent database storage
├── .env                 # Environment variables and secrets
├── docker-compose.yml   # Main Docker Compose configuration
├── galera.cnf           # MariaDB Galera cluster configuration
├── backup_galera.sh     # Backup script
├── LICENSE              # Project license
└── README.md            # Project documentation
```

## 🔍 Health Check

The cluster includes built-in health monitoring that checks database connectivity.

To manually check cluster health:
```bash
docker compose ps
# or
docker ps
```

The container will be marked as:
- `healthy`: When the database is responsive
- `unhealthy`: After 3 failed health checks
- `starting`: During the initial 30s start period

To manually check the cluster database:
```bash
# Size of cluster
docker exec -it <container_name_or_id> mariadb -u <username> -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

# IP adresses of cluster nodes
docker exec -it <container_name_or_id> mariadb -u <username> -p -e "SHOW STATUS LIKE 'wsrep_incoming_addresses';"

# All information about the cluster
docker exec -it <container_name_or_id> mariadb -u <username> -p -e "SHOW GLOBAL STATUS LIKE 'wsrep_%';"
```

## 📦 Backup

The project includes a backup script (`backup_galera.sh`) that safely creates backups of your Galera cluster:

### Backup
1. Make the script executable:
   ```bash
   chmod +x backup_galera.sh
   ```

2. Run the backup:
   ```bash
   ./backup_galera.sh
   ```

### Restore
1. Bind mount the backup directory to the container:
   ```bash
   ./backup:/backup
   ```
2. Untar the dump file:
   ```bash
   tar -xvzf /backup/galera-backup-YYYYMMDD.tar.gz
   ```
3. Enter the container:
   ```bash
   docker exec -it mariadb-galera /bin/bash
   ```
4. Restore the database:
   ```bash
   mariadb -u root -p < /backup/galera-backup-YYYYMMDD.sql
   ```
5. Note:
   ```bash
   You might need to set wsrep_new_cluster=ON in galera.cnf to get the container up and running,
   before entering the container.
   ```

The script will:
- Create backup and log directories
- Desynchronize the node to ensure consistent backup
- Create a MariaDB dump of all databases
- Create a compressed archive
- Re-synchronize the node with the cluster
- Log all operations

Backups and Logs are stored in the following structure:
```
backup/
├── temp/                          # Temporary storage for database dumps
└── galera-backup-YYYYMMDD.tar.gz  # Compressed backup archive
logs/
└── galera_backup.log              # Log file
```

You can also add the script to cron for automated backups:
```bash
# Example: Run backup daily at 2 AM
0 2 * * * /path/to/backup_galera.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🆘 Support

If you encounter any issues or need support, please file an issue on the GitHub repository.

## 📄 License

This project is licensed under the GNU GENERAL PUBLIC LICENSE v3.0 - see the [LICENSE](LICENSE) file for details.