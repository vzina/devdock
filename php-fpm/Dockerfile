ARG DEVDOCK_PHP_VERSION

FROM laradock/php-fpm:2.7-${DEVDOCK_PHP_VERSION}

LABEL maintainer="Weijian Ye <yeweijian299@163.com>"

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

###########################################################################
# Set Timezone
###########################################################################

ARG TZ=UTC
ENV TZ ${TZ}

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG WORKPATH=/data/web

# Set default work directory
WORKDIR ${WORKPATH}

EXPOSE 9000