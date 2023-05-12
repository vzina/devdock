ARG DEVDOCK_PHP_VERSION

FROM laradock/workspace:master-${DEVDOCK_PHP_VERSION}

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

RUN apt-get update \
    && apt-get install -y wget \
        iputils-ping \
        libevent-dev \
        librabbitmq-dev \
        libssl-dev

# always run apt update when start and after add new source list, then clean up at end.
RUN pecl channel-update pecl.php.net && \
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
    echo "extension=amqp.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/amqp.ini && \
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
    echo "extension=redis.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/redis.ini && \
    phpenmod redis \
;fi

###########################################################################
# PHP REDIS EXTENSION
###########################################################################
USER root

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
    && echo "extension=swoole.so" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/swoole.ini \
    && echo "swoole.use_shortname=off" >> /etc/php/${DEVDOCK_PHP_VERSION}/mods-available/swoole.ini \
    && phpenmod swoole \
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
