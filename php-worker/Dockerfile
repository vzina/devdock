ARG PHP_VERSION=${PHP_VERSION}

FROM php:${PHP_VERSION}-alpine

LABEL maintainer="Weijian Ye <yeweijian299@163.com>"

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

# If you're in China, or you need to change sources, will be set CHANGE_SOURCE to true in .env.

ARG CHANGE_SOURCE=false
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    # Change application source from dl-cdn.alpinelinux.org to aliyun source
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories \
;fi

RUN apk --update add wget \
        cmake \
        curl \
        git \
        build-base \
        libmemcached-dev \
        libmcrypt-dev \
        libxml2-dev \
        zlib-dev \
        autoconf \
        cyrus-sasl-dev \
        libgsasl-dev \
        libevent-dev \
        supervisor

RUN docker-php-ext-install mysqli \
        mbstring pdo \
        pdo_mysql \
        tokenizer \
        xml \
        pcntl \
        sysvsem \
        sysvshm \
        sysvmsg

###########################################################################
# Set Timezone
###########################################################################

ARG TZ=UTC
ENV TZ ${TZ}

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./php.ini /usr/local/etc/php/php.ini

###########################################################################
# AMQP:
###########################################################################

ARG INSTALL_AMQP=false

RUN if [ ${INSTALL_AMQP} = true ]; then \
    apk add rabbitmq-c rabbitmq-c-dev \
        && pecl install amqp \
        && docker-php-ext-enable amqp \
;fi


###########################################################################
# Swoole EXTENSION
###########################################################################

ARG INSTALL_SWOOLE=false

RUN if [ ${INSTALL_SWOOLE} = true ]; then \
    # Install PHP Swoole Extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        pecl -q install -o -f swoole-2.0.11 && \
        docker-php-ext-enable swoole; \
    else \
        cd /tmp && wget https://pecl.php.net/get/swoole-4.4.16.tgz && \
        tar zxf swoole-4.4.16.tgz && \
        cd swoole-4.4.16  && \
        phpize  && \
        ./configure  --enable-openssl && \
        make && make install && \
        docker-php-ext-enable swoole && \
        echo 'swoole.use_shortname = off' >> /usr/local/etc/php/php.ini && \
        php --ri swoole; \
    fi
;fi

###########################################################################
# PHP REDIS EXTENSION
###########################################################################

ARG INSTALL_PHPREDIS=false

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # Install Php Redis extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        printf "\n" | pecl -q install -o -f redis-4.2.0; \
    else \
        printf "\n" | pecl -q install -o -f redis; \
    fi && \
    docker-php-ext-enable redis \
;fi

###########################################################################
# PHP MEMCACHED EXTENSION
###########################################################################

ARG INSTALL_MEMCACHED=false

RUN if [ ${INSTALL_MEMCACHED} = true ]; then \
    # Install Php Redis extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        printf "\n" | pecl -q install -o -f memcached-3.0.4; \
    else \
        printf "\n" | pecl -q install -o -f memcached; \
    fi &&\
    docker-php-ext-enable memcached \
;fi

###########################################################################
# PHP MEMCACHE EXTENSION
###########################################################################

ARG INSTALL_MEMCACHE=false

RUN if [ ${INSTALL_MEMCACHE} = true ]; then \
    # Install Php Memcache extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        printf "\n" | pecl -q install -o -f memcache-2.2.7; \
    else \
        printf "\n" | pecl -q install -o -f memcache; \
    fi && \
    # echo "extension=memcache.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/memcache.ini && \
    phpenmod memcache \
;fi

RUN rm /var/cache/apk/* \
    && mkdir -p /var/www

#
#--------------------------------------------------------------------------
# Optional Supervisord Configuration
#--------------------------------------------------------------------------
#
# Modify the ./supervisor.conf file to match your App's requirements.
# Make sure you rebuild your container with every change.
#

COPY supervisord.conf /etc/supervisord.conf

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]

#
#--------------------------------------------------------------------------
# Optional Software's Installation
#--------------------------------------------------------------------------
#
# If you need to modify this image, feel free to do it right here.
#
    # -- Your awesome modifications go here -- #

#
#--------------------------------------------------------------------------
# Check PHP version
#--------------------------------------------------------------------------
#

RUN php -v | head -n 1 | grep -q "PHP ${PHP_VERSION}."

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

RUN mkdir -p /data/logs

WORKDIR /etc/supervisor/conf.d/
