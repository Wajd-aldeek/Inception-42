FROM debian:12.15

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl
COPY conf/nginx.conf /etc/nginx/templates/wordpress.conf.template

COPY ./tools/nginx.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx.sh

EXPOSE 443

ENTRYPOINT ["nginx.sh"]
