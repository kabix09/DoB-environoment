FROM php:7.4-fpm-buster
#FROM php:7.4-fpm
#debian:bullseye-slim
#FROM php:7.4-fpm-alpine

RUN apt-get update && apt-get install -y gnupg2

#RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#RUN curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list
#RUN apt-get update \
#    && apt-get install -y --no-install-recommends \
#        locales \
#        apt-transport-https \
#    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
#    && locale-gen \
#    && apt-get update \

#ERROR FOR 'MBSTRING' library -     https://stackoverflow.com/questions/59251008/docker-laravel-configure-error-package-requirements-oniguruma-were-not-m
RUN apt-get update \
    && apt-get install -y curl apt-transport-https multiarch-support \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get --no-install-recommends install -y zlib1g-dev g++ git libicu-dev libzip-dev zip libsodium-dev libcurl4-openssl-dev unixodbc-dev msodbcsql17 libxslt1-dev librabbitmq-dev libssh-dev \
    && docker-php-ext-install intl opcache pdo pdo_mysql curl sodium bcmath sockets xsl \
    && pecl install apcu sqlsrv pdo_sqlsrv xdebug amqp \
    && docker-php-ext-enable apcu sqlsrv pdo_sqlsrv xdebug amqp \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip

RUN pecl install -o -f redis \
  &&  rm -rf /tmp/pear \
  &&  docker-php-ext-enable redis

###
#     https://stackoverflow.com/questions/65554220/trying-to-add-libxslt-to-docker-container
# xsl - extension for 'inky_to_html'
# apt-get install libxslt1-dev - for library for xml, necessary for project
# docker-php-ext-install xsl - for enable extension in php.ini file

### add microsoft sqlsrv library
#     https://laravel-news.com/install-microsoft-sql-drivers-php-7-docker
#     https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsFROM php:7.4-fpmft-odbc-driver-for-sql-server?view=sql-server-2017
#     https://docs.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-ver15#installing-on-debian

# https://github.com/MicrosoftDocs/sql-docs/issues/6494

# 'docker php-fpm cant install msodbcsql17'   - https://github.com/laradock/laradock/issues/3042

# RUN apt-get update \
#    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
#    && curl https://packages.microsoft.com/config/debian/9/prod.list \
#       > /etc/apt/sources.list.d/mssql-release.list \
#    && apt-get -y --no-install-recommends install \
#       unixodbc-dev \
#       msodbcsql17


### add curl
# install -y libcurl4-openssl-dev
# docker-php-ext-install curl

### add redis tools 
### source: https://stackoverflow.com/questions/31369867/how-to-install-php-redis-extension-using-the-official-php-docker-image-approach
#RUN pecl install -o -f redis \
#  &&  rm -rf /tmp/pear \
#  &&  docker-php-ext-enable redis

### add rabbitMQ
# source: https://github.com/php-amqplib/php-amqplib/issues/521
# docker-php-ext-install bcmath sockets
# apt-get install php-amqp - library for php

WORKDIR /var/www/project

#RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#RUN php composer-setup.php
#RUN php -r "unlink('composer-setup.php');"
#RUN mv composer.phar /usr/local/bin/composer
#RUN chmod +x /usr/local/bin/composer
#RUN ln -snf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony/bin/symfony /usr/local/bin/symfony

#RUN git config --global user.email "you@example.com" \ 
#    && git config --global user.name "Your Name"



# template how to copy volumes with libraries: https://stackoverflow.com/questions/56027785/docker-failed-to-install-curl-version-7-10-5-or-later-is-required

### configuration files:
# ls -la ./usr/local/etc/
# ls -la ./usr/local/etc/php - php.ini

## instal composer dependecies
# https://stackoverflow.com/questions/66283653/how-to-install-composer-dependencies-in-a-container

# https://medium.com/@takeit/how-to-setup-docker-for-symfony-4-applications-f3c63ac96fc6

CMD /bin/bash /scripts/entrypoint.sh
