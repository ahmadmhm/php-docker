FROM alpine:3.13
LABEL Maintainer="Morteza Fathi <mortezaa.fathi@gmail.com>" \
      Description="Lightweight container with Nginx 1.18 & PHP-FPM 8 based on Alpine Linux."

ENV ALPINE_VERSION=3.13
ENV APK_MAIN_MIRROR=http://dl-5.alpinelinux.org/alpine/v$ALPINE_VERSION/main
ENV APK_COMUNITTY_MIRROR=http://dl-5.alpinelinux.org/alpine/v$ALPINE_VERSION/community

RUN echo $APK_MAIN_MIRROR > /etc/apk/repositories
RUN echo $APK_COMUNITTY_MIRROR >> /etc/apk/repositories

# Install packages
RUN apk --no-cache add php7 \
    php7-common \
    php7-fpm \
    php7-pdo \
    php7-opcache \
    php7-zip \
    php7-phar \
    php7-iconv \
    php7-cli \
    php7-curl \
    php7-openssl \
    php7-mbstring \
    php7-tokenizer \
    php7-fileinfo \
    php7-json \
    php7-xml \
    php7-xmlwriter \
    php7-simplexml \
    php7-dom \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-tokenizer \
    php7-pecl-redis \
    nginx supervisor curl tzdata nano git vim redis htop mysql-client


# Install additional php extentions and remove default server definition
RUN apk --no-cache add php7-ctype \
   php7-sockets \
   php7-pcntl \
   php7-intl \
   php7-xmlreader \
   php7-gd \
   php7-posix\
   php7-bcmath \
   php7-gmp \
   php7-soap \
   php7-mysqli

RUN rm /etc/nginx/conf.d/default.conf

# Symlink php7 => php
#RUN ln -s /usr/bin/php /usr/bin/php

# Install PHP tools
COPY --from=composer:2.3 /usr/bin/composer /usr/local/bin/composer

# Configure nginx
COPY .docker/dev/config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY .docker/dev/config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY .docker/dev/config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY .docker/dev/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN set -x \
	&& adduser -u 1000 -D -S -G www-data www-data

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R www-data.www-data /var/www/html && \
  chown -R www-data.www-data /run && \
  chown -R www-data.www-data /var/lib/nginx && \
  chown -R www-data.www-data /var/log/nginx

# Switch to use a non-root user from here on
USER www-data

# Add application
WORKDIR /var/www/html
COPY --chown=www-data ./ /var/www/html/

RUN chmod 777 -R storage/ \
 && chmod 777 -R bootstrap/cache/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
ENTRYPOINT [".docker/dev/docker-entrypoint.sh"]
