#!/bin/bash

set -e

if [ ! -f /var/www/html/wp-config.php ]; then
    
    cd /var/www/html
    rm -rf ./*

    curl -4 -fL \
        --retry 5 \
        --connect-timeout 10 \
        --max-time 120 \
        -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

	chmod +x /usr/local/bin/wp
   	 wp core download --allow-root

    DB_PASSWORD=$(cat /run/secrets/db_password)
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_EMAIL}" \
        --allow-root

    wp user create \
        "${WP_NORMAL_USER:-normal_user}" \
        "${WP_NORMAL_EMAIL:-user@wal-deek.42.fr}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
fi

mkdir -p /run/php

exec php-fpm8.2 -F
