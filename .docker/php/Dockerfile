# Composer Build Stage
FROM composer:lts AS vendor

# Node Build Stage
FROM node:lts-alpine3.21 AS frontend

# PHP Build Stage
FROM php:8.4-fpm-alpine3.21

COPY .docker/php/config/dev.ini /usr/local/etc/php/conf.d/
COPY .docker/php/config/file-uploads.ini /usr/local/etc/php/conf.d/zzz-file-uploads-config.ini

ENV APP_HOME /var/www/html

# Update apk repositories and install build dependencies along with runtime dependencies
RUN apk update \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        zlib-dev \
    && apk add --no-cache \
        curl \
        freetype \
        libjpeg-turbo \
        libpng \
        libpq \
        libstdc++ \
        libzip-dev \
        postgresql-dev \
        unzip \
        zip \
    && pecl install redis \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql zip \
    && docker-php-ext-enable opcache redis.so \
    && apk del .build-deps

# Copy project to image
COPY . /var/www/html

# Composer
COPY --from=vendor /usr/bin/composer /usr/bin/composer

# Node
COPY --from=frontend /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=frontend /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && npm install -g npx

# Set working directory
WORKDIR /var/www/html

# Add a non-root user to prevent files being created with root permissions on host machine.
ENV USER=admin
ENV UID 1000
ENV GID 1000

RUN addgroup --gid "$GID" "$USER" \
    && adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$USER" \
    --no-create-home \
    --uid "$UID" \
    "$USER"  \
    && mkdir -p /home/$USER/.composer \
    && chown -R $USER:$USER /home/$USER \
    && chown -R $USER:$GID /var/www \
    && chmod -R 0755 /var/www/html/bootstrap/cache /var/www/html/storage/framework /var/www/html/storage/logs

USER $USER