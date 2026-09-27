# User Documentation

## Services Provided

This application provides a WordPress website over HTTPS.

Its services are:

| Service | Role |
| --- | --- |
| NGINX | Receives browser requests, handles TLS, and serves static files |
| WordPress with PHP-FPM | Runs the website and administration interface |
| MariaDB | Stores articles, users, settings, and other database records |

Only HTTPS port 443 is published by the application.

## Start the Application

Open a terminal inside the VM and enter the project directory:

```bash
cd ~/Inception
```

Build and start the application:

```bash
make
```

When the existing images are suitable and no build is needed:

```bash
make up
```

The first initialization may take longer because WordPress and its command-line tool may need to be downloaded.

## Stop and Resume

Stop the application while keeping its containers:

```bash
make stop
```

Resume those same containers:

```bash
make start
```

To remove the containers and project network while keeping persistent storage:

```bash
make down
```

Recreate and start them afterward:

```bash
make up
```

## Access the Website

The current configuration uses:

```text
https://wal_deek.42.fr
```

Open the administration interface at:

```text
https://wal_deek.42.fr/wp-admin/
```

The name must resolve on the machine running the browser.

If the browser runs on the physical host, configuring name resolution only inside the VM is not enough.

For a VM whose IP is directly reachable, add a mapping on the browser's machine:

```text
<VM_IP> wal_deek.42.fr
```

Replace `<VM_IP>` with the actual reachable VM address.

If the VM uses NAT and is not directly reachable, configure the hypervisor's port forwarding as well. Docker's port publishing exposes port 443 on the VM; it does not automatically configure forwarding from the physical host into the VM.

The final domain must be reconciled with the subject's required learner-login format.

### Certificate Warning

The project uses a self-signed TLS certificate.

The browser may warn that it cannot verify the certificate's issuer. This does not mean the connection is unencrypted. Verify that you are accessing your own VM before accepting the certificate for local testing.

## Credentials

Non-secret configuration is stored in:

```text
srcs/.env
```

The administrator username is configured through:

```text
WP_USER
```

The current configured administrator username is:

```text
deek_author
```

Despite its name, this is the account passed to WordPress installation as the administrator.

The startup script currently defaults the additional WordPress account to `normal_user` with the `author` role unless overridden.

Passwords are stored locally in these files:

| File | Purpose |
| --- | --- |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | Password for the WordPress database account |
| `secrets/wp_admin_password.txt` | Initial WordPress administrator password |
| `secrets/wp_user_password.txt` | Initial additional WordPress user password |

Do not publish these files or commit their contents to Git.

### Managing Passwords

Use the WordPress administration interface to update existing WordPress account passwords.

Changing a secret file does not automatically change the password already stored in WordPress or MariaDB.

Database password changes must be coordinated with the database account and the WordPress connection configuration. Ask the maintainer to perform this operation.

Do not reset the entire application merely to change a password.

## Check Service Status

From the repository root:

```bash
docker compose -f srcs/docker-compose.yml ps -a
```

Expected normal state:

- MariaDB: running and healthy.
- WordPress: running and healthy.
- NGINX: running.

The configured WordPress health check only checks whether PHP-FPM is running. Test the website as well.

View recent logs:

```bash
docker compose -f srcs/docker-compose.yml logs --tail 100
```

View one service:

```bash
docker compose -f srcs/docker-compose.yml logs --tail 100 mariadb
```

### Test HTTPS Inside the VM

```bash
curl -kI --resolve wal_deek.42.fr:443:127.0.0.1 https://wal_deek.42.fr
```

- `-I` requests response headers.
- `-k` skips certificate verification for the self-signed certificate; TLS encryption remains enabled.
- `--resolve` supplies the address for this request without modifying system name resolution.

A `200 OK` response indicates that this request succeeded. It does not verify every application feature or prove that previous user data was preserved.

## First-Startup Troubleshooting

A known issue is that MariaDB initialization on empty storage can take longer than the configured health-check allowance.

If startup reports MariaDB as unhealthy:

1. Inspect its logs and current status.
2. Do not repeatedly delete data.
3. If MariaDB subsequently becomes healthy, run:

```bash
make up
```

This allows dependent services to start.

The maintainer should adjust the initial health-check grace period and repeat the empty-storage test.

## Persistent Data and Destructive Commands

The current backing directories inside the VM are:

```text
/home/wal-deek/data/wordpress
/home/wal-deek/data/mariadb
```

Stopping or removing containers does not, by itself, delete these files.

The following commands are destructive:

```bash
make fclean
make re
```

They remove application data through the Makefile's deletion commands. Recovering deleted articles requires a backup; rebuilding an image does not restore them.

`make clean` removes Docker volume definitions and service images. With the current local-driver backing-directory configuration, the backing files remain on disk.

Before any destructive maintenance, back up both the database and uploaded website files. Ask the maintainer for a database-aware backup procedure.
