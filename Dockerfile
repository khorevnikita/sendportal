FROM php:8.0-fpm AS base

ARG APPNAME="SendPortal"

ENV APPNAME=$APPNAME

RUN apt-get update && apt-get install -y \
        libzip-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        ffmpeg \
        nginx \
        curl \
        gnupg \
        nano \
        supervisor \
        pngquant \
        libgmp-dev \
        re2c \
        libmhash-dev \
        libmcrypt-dev \
        file \
        wget \
        apache2-utils \
        gettext-base \
        cron \
        sudo \
        librdkafka-dev \
        libpq-dev

ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#RUN pecl install redis-5.1.1 \
#    && pecl install xdebug-2.8.1 \
#    && docker-php-ext-enable redis xdebug

RUN docker-php-ext-install pdo_mysql \
&& docker-php-ext-install pdo_pgsql \
&& docker-php-ext-install gd \
&& docker-php-ext-install zip \
&& docker-php-ext-install opcache

RUN apt-get -y install \
            libmagickwand-dev \
        --no-install-recommends \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && rm -r /var/lib/apt/lists/*

# Install Nodejs and NPM
RUN curl -sL https://deb.nodesource.com/setup_14.x  | bash -
RUN apt-get -y install nodejs

#RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/
RUN docker-php-ext-configure gmp
RUN docker-php-ext-install gmp

COPY docker/mysql.list /etc/apt/sources.list.d/mysql.list
COPY docker/mysql.asc /tmp/mysql.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
RUN apt-key add /tmp/mysql.asc && apt-get update && apt-get install -y mysql-community-client unzip
#RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
#RUN dpkg -i mysql-apt-config_0.8.13-1_all.deb && rm mysql-apt-config_0.8.13-1_all.deb && apt-get update && apt-get install -y mysql-community-client unzip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install && rm -rf ./aws awscliv2.zip

COPY --from=composer /usr/bin/composer /usr/bin/composer

FROM node:12 AS build-stg
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y autoconf libtool pkg-config nasm
RUN mkdir /build && chown node:node /build
COPY --chown=node ./ /build/
USER node
WORKDIR /build
#RUN yarn install
#RUN yarn run prod

FROM base AS run-stg

COPY docker/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/supervisord.cron.conf /etc/supervisor/conf.d/supervisord.cron.conf

RUN mkdir -p ~/.mysql && wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" -O ~/.mysql/root.crt && chmod 0600 ~/.mysql/root.crt

# Expose the port nginx is reachable on
EXPOSE 8080

ADD docker/entrypoint.sh /entrypoint.sh
ADD docker/backup.sh /backup.sh
ADD docker/crontab /var/spool/cron/crontabs/root

# Modifying the Groups and Permissions of Root Files
RUN chown -R root:crontab /var/spool/cron/crontabs/root \
 && chmod 600 /var/spool/cron/crontabs/root

# Create log file
RUN touch /var/log/cron.log
RUN chmod +x /*.sh

# Ensure PHP logs are captured by the container
ENV LOG_CHANNEL=stderr

# Add application
WORKDIR /var/www/html

COPY --chown=www-data:www-data --from=build-stg /build/ /var/www/html/
#COPY contest/ /var/www/html/
RUN composer install --optimize-autoloader --no-interaction --no-progress && rm -rf /var/www/html/.composer/cache

RUN chmod -R a+w /var/www/html/storage


# Let supervisord start nginx & php-fpm
CMD ["/entrypoint.sh"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

