# 💾 MariaDB Galera Cluster with Docker Compose

A MariaDB Galera Cluster setup using Docker Compose.

## ✨ Features

- Multi-node MariaDB Galera Cluster
- Automatic node synchronization
- Built-in health monitoring
- Environment-based configuration
- Persistent data storage
- Custom Galera configuration

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

3. For the first node only, set `wsrep_new_cluster=ON` in galera.cnf to bootstrap the cluster:
   ```bash
   # Edit galera.cnf and set
   wsrep_new_cluster=ON  # Set to ON for the first node only
   ```

4. Start the cluster:
   ```bash
   docker compose up -d
   ```

5. After the first node is running, set `wsrep_new_cluster=OFF` and start additional nodes:
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
├── docker-compose.yml    # Main Docker Compose configuration
├── galera.cnf           # MariaDB Galera cluster configuration
├── LICENSE             # Project license
└── README.md           # Project documentation
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

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🆘 Support

If you encounter any issues or need support, please file an issue on the GitHub repository.

## 📄 License

This project is licensed under the GNU GENERAL PUBLIC LICENSE v3.0 - see the [LICENSE](LICENSE) file for details.