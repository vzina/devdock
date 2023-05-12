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
        curl-dev \
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
        supervisor; \
        if [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "50600" ] || \
            [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70000" ]; then \
            apk --update add libressl libressl-dev; \
        else \
            apk --update add openssl-dev; \
        fi

RUN pecl channel-update pecl.php.net; \
    docker-php-ext-install mysqli \
        mbstring pdo \
        pdo_mysql \
        tokenizer \
        xml \
        pcntl \
        sysvsem \
        sysvshm \
        sysvmsg; \
        if [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "80100" ] || \
            [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "80200" ]; then \
            php -m | grep -oiE '^tokenizer$'; \
        else \
            docker-php-ext-install tokenizer; \
        fi


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
    # Install Php Redis extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        SW_VERSION=v2.0.11; \
    elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
        SW_VERSION=v4.8.13; \
    else \
        SW_VERSION=v5.0.3; \
    fi \
    && cd /tmp \
    && curl -SL "https://github.com/swoole/swoole-src/archive/${SW_VERSION}.tar.gz" -o swoole.tar.gz \
    && ls -alh \
    # php extension:swoole
    && cd /tmp \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-openssl --enable-http2 --enable-swoole-curl --enable-swoole-json \
        && make -s -j$(nproc) && make install \
    ) \
    && echo "swoole.use_shortname=off" >> /usr/local/etc/php/php.ini \
    && docker-php-ext-enable swoole \
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
