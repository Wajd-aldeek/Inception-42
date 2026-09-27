*This activity has been created as part of the 42 curriculum by wal-deek.*

# Inception

## Description

Inception is a system administration project that runs a WordPress website using Docker Compose inside a virtual machine.

The infrastructure contains three services, each running in a separate container:

- NGINX: accepts HTTPS requests on port 443 and forwards PHP requests to PHP-FPM.
- WordPress with PHP-FPM: executes the WordPress application.
- MariaDB: stores the WordPress database.

The project uses custom Dockerfiles based on Debian Bookworm, a dedicated Docker bridge network, persistent storage, environment variables, and Docker Compose secrets.

## Project Description

### Architecture

NGINX is the only service with a published port.

Static website files are served directly by NGINX. Requests requiring PHP execution are forwarded to the WordPress service using FastCGI on port 9000.

PHP-FPM workers execute WordPress code. When that code needs database information, it communicates with MariaDB on port 3306.

NGINX terminates TLS using a self-signed certificate. Its website configuration allows TLS 1.2 and TLS 1.3.

### Project Files

| Path | Purpose |
| --- | --- |
| `Makefile` | Build, start, stop, and clean the infrastructure |
| `srcs/docker-compose.yml` | Define services, dependencies, networking, volumes, and secrets |
| `srcs/.env` | Store non-secret configuration values |
| `srcs/requirements/nginx/` | NGINX Dockerfile, configuration, and startup script |
| `srcs/requirements/wordpress/` | WordPress Dockerfile, PHP-FPM configuration, and startup script |
| `srcs/requirements/mariadb/` | MariaDB Dockerfile, configuration, and startup script |
| `secrets/` | Local password files that must not be committed |
| `USER_DOC.md` | Instructions for users and administrators |
| `DEV_DOC.md` | Setup, maintenance, and development instructions |

### Design Choices

- Each service has its own container and Dockerfile.
- Debian Bookworm provides the base userland and packages.
- Containers communicate using service names on a dedicated bridge network.
- Only NGINX publishes a port to the VM.
- WordPress files and database files use separate persistent volumes.
- Passwords are read from secret files instead of being written into Dockerfiles.
- Startup scripts prepare each service before replacing the shell with its main process.
- Health checks and dependency conditions control startup ordering.
- Restart policies restart containers after their main process exits, subject to Docker's restart-policy behavior.

### Virtual Machines vs Docker

A virtual machine runs its own operating system kernel on virtualized hardware.

Containers share the kernel of the machine running Docker, while isolating processes, filesystems, and networking.

In this project, Docker runs inside a VM. All three containers share the VM's Linux kernel.

### Secrets vs Environment Variables

Environment variables are convenient for configuration such as database names and domain names. Values passed to containers through their environment can be exposed by container inspection.

Compose secrets make selected files available only to the services explicitly granted access. The startup scripts read them from `/run/secrets/`.

With local Docker Compose, file-based secrets are mounted from local files. This does not provide the same encrypted secret-management system as Docker Swarm. Host file permissions and excluding secrets from Git remain necessary.

### Docker Network vs Host Network

A Docker bridge network gives containers separate network namespaces and allows communication through service names.

Host networking shares the host's network namespace and reduces network isolation.

This project uses a bridge network named `inception` in the Compose configuration. Host networking is not used.

### Docker Volumes vs Bind Mounts

A named volume is a Docker-managed storage resource referenced by name.

A bind mount directly exposes a host path inside a container.

The current configuration declares named volumes and uses the local volume driver with bind options to place their data in:

- `/home/wal-deek/data/wordpress`
- `/home/wal-deek/data/mariadb`

These resources are named volumes at the Docker API level, but their backing storage uses host directories through bind options. This implementation must be reviewed against the subject's explicit restriction on bind mounts before final submission.

Removing these named volume definitions does not automatically erase the contents of their backing directories.

## Instructions

### Requirements

- A Linux virtual machine.
- Docker Engine and the Docker Compose plugin.
- GNU Make.
- Internet access for initial package and WordPress downloads.
- Permission to use Docker.
- Administrative privileges inside the VM for operations that require them.

### Configuration

Before starting:

1. Configure `srcs/.env`.
2. Create the four password files described in `DEV_DOC.md`.
3. Ensure secrets are excluded from Git.
4. Configure name resolution on the machine used to access the website.
5. Ensure the VM is reachable on the required HTTPS port.

### Build and Start

Run from the repository root:

```bash
make
```

This creates the data directories and invokes:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

### Common Commands

| Command | Effect |
| --- | --- |
| `make` or `make all` | Build images and create or update and start services |
| `make up` | Create or update and start services without explicitly forcing a build |
| `make stop` | Stop containers without removing them |
| `make start` | Start existing stopped containers |
| `make down` | Remove project containers and network while retaining named volumes and images |
| `make clean` | Remove project containers, network, named volumes, and service images |
| `make fclean` | Run `clean`, then delete matching contents of the data directories |
| `make re` | Run `fclean`, then build and start the application |

`make fclean` and `make re` delete application data. They must not be used as routine update commands.

### Access

The currently configured URL is:

```text
https://wal_deek.42.fr
```

The administration page is:

```text
https://wal_deek.42.fr/wp-admin/
```

The current domain contains an underscore. Before final submission, reconcile it with the subject's required `<login>.42.fr` format and the learner login `wal-deek`.

A browser warning is expected unless the self-signed certificate is explicitly trusted.

## Current Validation Status

The following operations were tested:

- Building and starting the services.
- Stopping and starting existing containers.
- Removing and recreating containers.
- Cleaning persistent data and initializing the application again.
- Receiving an HTTPS `200 OK` response from the website.

The following points remain open before final submission:

- Set explicit image names matching their services and use explicit non-`latest` tags. Current automatic names are `srcs-nginx:latest`, `srcs-wordpress:latest`, and `srcs-mariadb:latest`.
- Add an appropriate initial health-check grace period for MariaDB and repeat the empty-data startup test. The observed initial startup exceeded the current health-check allowance.
- Verify the domain against the learner login.
- Resolve the storage implementation against the subject's no-bind-mount requirement.
- Review application initialization and readiness checks. The WordPress health check currently verifies PHP-FPM process presence, not complete website functionality.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB documentation](https://mariadb.com/docs/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI documentation](https://make.wordpress.org/cli/handbook/)
- The supplied Inception subject, version 1.5.

### AI Usage

AI was used to assist with:

- Explaining Docker, Compose, persistence, networking, PID 1, TLS, and startup behavior.
- Investigating PHP package-version mismatches, missing secrets, database initialization, health-check timing, and NGINX configuration loading.
- Reviewing Makefile commands and their effects.
- Preparing documentation and defense-review questions.

Suggested changes were reviewed and tested in the VM. Remaining issues are documented above. The learner is responsible for understanding, verifying, and maintaining the submitted configuration.
