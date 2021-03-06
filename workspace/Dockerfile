ARG DEVDOCK_PHP_VERSION

FROM laradock/workspace:2.6.1-${DEVDOCK_PHP_VERSION}

LABEL maintainer="Weijian Ye <yeweijian299@163.com>"

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

# If you're in China, or you need to change sources, will be set CHANGE_SOURCE to true in .env.

ARG CHANGE_SOURCE=false
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    # Change application source from deb.debian.org to aliyun source
    sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
    sed -i 's/security-cdn.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list \
;fi

ARG DEVDOCK_PHP_VERSION

# Start as root
USER root

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

ARG CHANGE_SOURCE=false
ARG UBUNTU_SOURCE
COPY ./sources.sh /tmp/sources.sh

RUN if [ ${CHANGE_SOURCE} = true ]; then \
    chmod +x /tmp/sources.sh && \
    /bin/sh -c /tmp/sources.sh && \
    rm -rf /tmp/sources.sh \
;fi

# always run apt update when start and after add new source list, then clean up at end.
RUN apt-get update -yqq && \
    apt-get install -yqq iputils-ping libevent-dev zlib1g-dev wget libmemcached-dev librabbitmq-dev && \
    pecl channel-update pecl.php.net && \
    groupadd -g ${PGID} devdock && \
    useradd -u ${PUID} -g devdock -m devdock -G docker_env -s /bin/bash && \
    usermod -p "*" devdock

###########################################################################
# Set Timezone
###########################################################################

ARG TZ=UTC
ENV TZ ${TZ}

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

###########################################################################
# User Aliases
###########################################################################

USER root

COPY ./aliases.sh /root/aliases.sh
COPY ./aliases.sh /home/devdock/aliases.sh

RUN sed -i 's/\r//' /root/aliases.sh && \
    sed -i 's/\r//' /home/devdock/aliases.sh && \
    chown devdock:devdock /home/devdock/aliases.sh && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	echo "" >> ~/.bashrc

USER devdock

RUN echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	echo "" >> ~/.bashrc

###########################################################################
# Composer:
###########################################################################

USER root

# Add the composer.json
COPY ./composer.json /home/devdock/.composer/composer.json

# Make sure that ~/.composer belongs to devdock
RUN chown -R devdock:devdock /home/devdock/.composer

USER devdock

# Check if global install need to be ran
ARG COMPOSER_GLOBAL_INSTALL=false
ENV COMPOSER_GLOBAL_INSTALL ${COMPOSER_GLOBAL_INSTALL}

RUN if [ ${COMPOSER_GLOBAL_INSTALL} = true ]; then \
    # run the install
    composer global install \
;fi

ARG COMPOSER_REPO_PACKAGIST
ENV COMPOSER_REPO_PACKAGIST ${COMPOSER_REPO_PACKAGIST}

RUN if [ ${COMPOSER_REPO_PACKAGIST} ]; then \
    composer config -g repo.packagist composer ${COMPOSER_REPO_PACKAGIST} \
;fi

# Export composer vendor path
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="~/.composer/vendor/bin:$PATH"' >> ~/.bashrc

###########################################################################
# Crontab
###########################################################################

USER root

COPY ./crontab /etc/cron.d

RUN chmod -R 644 /etc/cron.d

###########################################################################
# ssh:
###########################################################################
USER root

ARG INSTALL_WORKSPACE_SSH=false

COPY insecure_id_rsa /tmp/id_rsa
COPY insecure_id_rsa.pub /tmp/id_rsa.pub

RUN if [ ${INSTALL_WORKSPACE_SSH} = true ]; then \
    rm -f /etc/service/sshd/down && \
    cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys \
        && cat /tmp/id_rsa.pub >> /root/.ssh/id_rsa.pub \
        && cat /tmp/id_rsa >> /root/.ssh/id_rsa \
        && rm -f /tmp/id_rsa* \
        && chmod 644 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub \
    && chmod 400 /root/.ssh/id_rsa \
    && cp -rf /root/.ssh /home/devdock \
    && chown -R devdock:devdock /home/devdock/.ssh \
;fi

###########################################################################
# AMQP:
###########################################################################
USER root

ARG INSTALL_AMQP=false

RUN if [ ${INSTALL_AMQP} = true ]; then \
    pecl -q install -o -f amqp && \
    # echo "extension=amqp.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/amqp.ini && \
    # ln -s /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/amqp.ini /etc/php/${DEVDOCK_PHP_VERSION}/cli/conf.d/30-amqp.ini \
    phpenmod amqp \
;fi

###########################################################################
# PHP REDIS EXTENSION
###########################################################################
USER root

ARG INSTALL_PHPREDIS=false

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # Install Php Redis extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        printf "\n" | pecl -q install -o -f redis-4.2.0; \
    else \
        printf "\n" | pecl -q install -o -f redis; \
    fi && \
    # echo "extension=redis.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/redis.ini && \
    phpenmod redis \
;fi

###########################################################################
# Swoole EXTENSION
###########################################################################
USER root

ARG INSTALL_SWOOLE=false

RUN if [ ${INSTALL_SWOOLE} = true ]; then \
    # Install Php Swoole Extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl -q install -o -f swoole-2.0.11; \
    else \
      if [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        pecl install -o -f swoole-2.2.0; \
      else \
        # pecl -q install -o -f swoole; \
        cd /tmp && \
            wget https://pecl.php.net/get/swoole-4.4.16.tgz && \
            tar zxf swoole-4.4.16.tgz && \
            cd swoole-4.4.16  && \
            phpize  && \
            ./configure  --enable-openssl && \
            make && make install && \
            echo "extension=swoole.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/swoole.ini && \
            echo "swoole.use_shortname = off" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/swoole.ini && \
            ln -s /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/swoole.ini /etc/php/${DEVDOCK_PHP_VERSION}/cli/conf.d/20-swoole.ini \
        ;fi \
    ;fi \
;fi

###########################################################################
# PHP MEMCACHED EXTENSION
###########################################################################
USER root

ARG INSTALL_MEMCACHED=false

RUN if [ ${INSTALL_MEMCACHED} = true ]; then \
    # Install Php Memcached extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        printf "\n" | pecl -q install -o -f memcached-2.2.0; \
    else \
        printf "\n" | pecl -q install -o -f memcached; \
    fi && \
    # echo "extension=memcached.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/memcached.ini && \
    phpenmod memcached \
;fi

###########################################################################
# PHP MEMCACHE EXTENSION
###########################################################################
USER root

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


###########################################################################
# PHP IMAP EXTENSION
###########################################################################
USER root

ARG INSTALL_IMAP=false

RUN if [ ${INSTALL_IMAP} = true ]; then \
    apt-get install -y php${DEVDOCK_PHP_VERSION}-imap \
;fi

###########################################################################
# Check PHP version:
###########################################################################

RUN php -v | head -n 1 | grep -q "PHP ${DEVDOCK_PHP_VERSION}."

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

USER root

ARG WORKPATH=/data/web

# Set default work directory
WORKDIR ${WORKPATH}
