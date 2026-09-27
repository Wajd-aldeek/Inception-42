#!/bin/bash

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=JO/ST=Amman/L=Amman/O=42/OU=42Amman/CN=${DOMAIN_NAME}"

envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/templates/wordpress.conf.template \
    > /etc/nginx/conf.d/wordpress.conf

rm -f /etc/nginx/sites-enabled/default
exec nginx -g "daemon off;"
