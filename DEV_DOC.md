# Developer Documentation

## Environment

The project runs entirely inside a Linux virtual machine.

Required software:

- Docker Engine.
- Docker Compose plugin.
- GNU Make.
- A text editor.
- curl for HTTP checks.
- Git for source management.

Initial builds and WordPress initialization require network access.

Check the installed tools:

```bash
docker --version
docker compose version
make --version
git --version
```

Check access to Docker:

```bash
docker info
```

Use the current Docker installation instructions for the VM's distribution when preparing a new environment.

Membership in the Docker group grants powerful access to the machine and should only be assigned to trusted users.

Administrative privileges inside the VM are separate from privileges on the physical host. The current Makefile uses `sudo` for deletion of data files owned by service users.

## Repository Layout

| Path | Contents |
| --- | --- |
| `Makefile` | Lifecycle commands |
| `srcs/docker-compose.yml` | Infrastructure configuration |
| `srcs/.env` | Runtime configuration values |
| `srcs/requirements/nginx/Dockerfile` | NGINX image build |
| `srcs/requirements/nginx/conf/nginx.conf` | Website configuration template |
| `srcs/requirements/nginx/tools/nginx.sh` | Certificate generation, configuration rendering, and NGINX startup |
| `srcs/requirements/wordpress/Dockerfile` | PHP-FPM and WordPress tooling image build |
| `srcs/requirements/wordpress/conf/www.conf` | PHP-FPM worker-pool configuration |
| `srcs/requirements/wordpress/tools/wordpress.sh` | WordPress initialization and PHP-FPM startup |
| `srcs/requirements/mariadb/Dockerfile` | MariaDB image build |
| `srcs/requirements/mariadb/conf/50-server.cnf` | Database server configuration |
| `srcs/requirements/mariadb/tools/mariadb.sh` | Database initialization and server startup |
| `secrets/` | Local password files |

Each service build directory also contains a `.dockerignore`.

## Setup from Scratch

### 1. Prepare the Repository

Place the repository at:

```text
/home/wal-deek/Inception
```

The current Makefile and volume definitions contain absolute paths under `/home/wal-deek/data`.

If installing under another account, update those paths consistently rather than changing only the repository location.

### 2. Configure Environment Variables

Create or review `srcs/.env`.

The current configuration uses these keys:

```dotenv
DOMAIN_NAME=wal_deek.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wal_deek
WP_TITLE=Inception_Project
WP_USER=deek_author
WP_EMAIL=wajd.al-deek@learner.42.tech
```

Use the actual operator's configuration when adapting the project.

`WP_USER` is the WordPress administrator account used during installation. Its name must respect the subject's restrictions on administrator usernames.

The current script also supports these optional variables:

```dotenv
WP_NORMAL_USER=normal_user
WP_NORMAL_EMAIL=user@wal-deek.42.fr
```

Before final submission, correct the domain consistently to match the learner login. Changing the environment alone does not rewrite an already-installed WordPress site's stored URL.

### 3. Create Secret Files

From the repository root:

```bash
mkdir -p secrets
chmod 700 secrets
```

Create the following files using a local editor, each containing its intended password:

```text
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Then restrict file access:

```bash
chmod 600 secrets/*.txt
```

Do not enter real passwords into Dockerfiles, documentation, or committed configuration.

Ensure the repository's `.gitignore` includes:

```gitignore
/secrets/
```

Before committing, verify that secrets are not already tracked:

```bash
git ls-files secrets
```

This should produce no secret-file entries. Ignoring a file does not remove it from existing Git history. Rotate any credentials that were previously exposed.

The current initialization script interpolates database passwords into SQL. SQL-sensitive characters require correct escaping; this remains a script-review item.

### 4. Configure Name Resolution and VM Networking

Configure the domain on the machine running the browser.

Use the VM's reachable address when direct access is available. For NAT-based access, configure the required hypervisor forwarding.

Docker publishes:

```text
VM port 443 -> NGINX container port 443
```

MariaDB and PHP-FPM are not published to the VM's external interfaces.

### 5. Build and Start

From the repository root:

```bash
make
```

This prepares the backing directories and runs:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

Validate status:

```bash
docker compose -f srcs/docker-compose.yml ps -a
```

Test HTTPS from inside the VM:

```bash
curl -kI --resolve wal_deek.42.fr:443:127.0.0.1 https://wal_deek.42.fr
```

## Build and Runtime Sequence

1. Make reads the Makefile and selects the requested target.
2. The default target creates the two data directories.
3. Compose reads the service definitions.
4. Docker builds the images using the configured build contexts and Dockerfiles.
5. Compose creates or reuses the required network and volumes.
6. Containers are created with their environment, mounts, secrets, and network attachments.
7. MariaDB starts.
8. WordPress starts after MariaDB satisfies the configured health condition.
9. NGINX starts after WordPress satisfies its health condition.

Build steps may use cache. `--build` does not mean every Dockerfile instruction executes again.

Copying a startup script into an image does not execute that script. The configured entrypoint executes when its container starts.

### MariaDB Initialization

The startup script:

- Creates runtime and data directories and sets ownership.
- Reads the database passwords from secrets.
- Checks for `/var/lib/mysql/mysql`.
- When that directory is absent, initializes database system tables.
- Starts a temporary server with networking disabled.
- Creates the application database and accounts.
- Stops the temporary server.
- Replaces the shell with the final database process.

The existence of the system-table directory is currently used as the initialization marker. Interrupted initialization can leave partially prepared data, so this logic needs review before being considered robust recovery behavior.

### WordPress Initialization

The startup script:

- Checks for `/var/www/html/wp-config.php`.
- When absent, downloads WP-CLI and WordPress.
- Reads passwords from the mounted secrets.
- Creates the database connection configuration.
- Installs WordPress and creates the additional user.
- Starts PHP-FPM in the foreground using `exec`.

The presence of `wp-config.php` does not prove that installation completed. An interrupted installation after configuration creation is a known recovery case to review.

### NGINX Startup

The startup script:

- Generates a self-signed certificate and private key.
- Substitutes the domain variable in the website template.
- Removes the default enabled site.
- Starts NGINX with daemon mode disabled using `exec`.

Only the intended domain variable should be substituted. NGINX variables such as `$uri` must remain intact.

## Network and Service Discovery

The services share the `inception` bridge network.

Internal connections use service names:

```text
NGINX -> wordpress:9000
WordPress -> mariadb:3306
```

Inside a container, `localhost` refers to that container's own network namespace.

TLS terminates at NGINX. The current FastCGI connection to PHP-FPM is not encrypted. Network isolation and encryption are different properties.

## Secrets

The top-level Compose secret definitions identify the source files.

Each service's `secrets` section grants that service access to selected files.

| Service | Mounted secrets |
| --- | --- |
| MariaDB | `db_password`, `db_root_password` |
| WordPress | `db_password`, `wp_admin_password`, `wp_user_password` |
| NGINX | None of these password secrets |

Default container paths are:

```text
/run/secrets/db_password
/run/secrets/db_root_password
/run/secrets/wp_admin_password
/run/secrets/wp_user_password
```

Only secrets granted to a service are mounted in its container.

Local Compose file secrets are file mounts, not an encrypted Swarm secret store.

## Persistent Storage

| Logical volume | Container path | Current backing directory in the VM |
| --- | --- | --- |
| `wordpress` | `/var/www/html` in WordPress and NGINX | `/home/wal-deek/data/wordpress` |
| `mariadb` | `/var/lib/mysql` in MariaDB | `/home/wal-deek/data/mariadb` |

The configuration uses named volumes with local-driver bind options. This needs reconciliation with the subject's explicit restriction on bind mounts before final validation.

The MariaDB mount includes:

```yaml
volume:
  nocopy: true
```

This prevents Docker from initially copying database files already present in the image into an empty volume. Such copying previously caused the initialization-directory check to skip application database creation.

### Persistence Behavior

- `stop` preserves the container's writable layer and persistent storage.
- `start` starts new processes in the same existing container.
- `down` removes containers and their writable layers but retains named volumes by default.
- Recreating a container reconnects it to existing persistent storage.
- An image is not a backup of runtime database contents.
- With the current backing-directory configuration, deleting the named volume resource leaves its backing directory contents on the VM.

User names displayed for file owners on the VM can differ from names inside containers because ownership is stored as numeric user and group IDs.

## Lifecycle Commands

Run these commands from the repository root.

| Command | Purpose |
| --- | --- |
| `make all` | Build and start the project |
| `make up` | Create or update and start services |
| `make stop` | Stop existing containers |
| `make start` | Start stopped existing containers |
| `make down` | Remove containers and the project network |
| `make clean` | Also remove named volumes and service images |
| `make fclean` | Also delete data-directory contents matched by the cleanup commands |
| `make re` | Clean data and rebuild and start the project |

The `re` target uses:

```makefile
re: fclean
	$(MAKE) all
```

This ensures its build command runs after its cleanup prerequisite completes successfully.

The current deletion commands use `sudo rm -rf .../*`. They do not match entries beginning with a dot directly inside the target directory.

## Applying Changes

### Dockerfile or Copied Configuration/Script Changes

```bash
make all
```

This requests a build and allows Compose to recreate affected containers.

A matching build cache can be reused. A changed build step generally invalidates subsequent dependent steps in the same build stage.

### Runtime Environment or Compose Configuration Changes

```bash
make up
```

Compose can recreate affected containers with updated configuration.

A restart of an existing container does not update its originally configured environment.

Changing initialization variables or secret files does not automatically alter database accounts or an existing WordPress installation.

## Inspection Commands

Show all project containers:

```bash
docker compose -f srcs/docker-compose.yml ps -a
```

Show running containers across Docker:

```bash
docker container ls
```

Show running and stopped containers across Docker:

```bash
docker container ls -a
```

Show images:

```bash
docker image ls
```

Show volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect srcs_mariadb
```

Show recent logs:

```bash
docker compose -f srcs/docker-compose.yml logs --no-color --tail 100
```

Inspect MariaDB health:

```bash
docker inspect mariadb --format='Status={{.State.Status}} Health={{.State.Health.Status}} Restarts={{.RestartCount}}'
```

Show MariaDB health-check results:

```bash
docker inspect mariadb --format='{{range .State.Health.Log}}{{println .End "Exit:" .ExitCode}}{{println .Output}}{{end}}'
```

Validate the loaded NGINX configuration:

```bash
docker exec nginx nginx -t
```

Validate Compose syntax and configuration:

```bash
docker compose -f srcs/docker-compose.yml config --quiet
```

## Known Issues and Final Validation

### Initial MariaDB Health-Check Timing

An empty-storage test showed that MariaDB could become unhealthy before initialization completed.

It later became healthy without a restart. Running `make up` then started WordPress and NGINX successfully.

Add an appropriate `start_period` to MariaDB's health check, review readiness detection during temporary-server initialization, and repeat the complete empty-data startup test. A successful manual retry does not establish that `make re` reliably succeeds in one attempt.

### Image Naming

The current Compose configuration does not explicitly set service image names. Builds therefore used project-prefixed names and the implicit `latest` tag.

Set image names matching the services with explicit non-`latest` tags, retain the custom build definitions, and verify the resulting images before submission.

### Domain

The current domain is `wal_deek.42.fr`, while the recorded learner login is `wal-deek`.

Reconcile the domain with the subject and update configuration, certificate generation, name resolution, and the stored WordPress URLs consistently.

### Storage

The current named volumes use the local driver's bind options.

Review this implementation against the exact subject requirements rather than treating a named resource alone as proof that the no-bind-mount requirement is satisfied.

### Final Checks

Before submission:

- Verify that all services build from the required permitted base release.
- Verify explicit image names and non-`latest` tags.
- Confirm only port 443 is published.
- Verify the effective NGINX TLS configuration permits only the required protocol versions.
- Confirm the administrator and additional WordPress account exist with appropriate roles.
- Confirm secrets are excluded from Git.
- Test persistence using an actual article and uploaded file across container recreation.
- Test crash recovery separately from health-check failure.
- Test initialization from empty data in one complete startup.
- Review the scripts' recovery behavior after interrupted initialization.
- Update all documentation after the remaining configuration changes.
