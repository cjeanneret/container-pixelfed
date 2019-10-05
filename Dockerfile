FROM php:7-fpm-alpine

ARG COMPOSER_VERSION="1.8.5"
ARG COMPOSER_CHECKSUM="4e4c1cd74b54a26618699f3190e6f5fc63bb308b13fa660f71f2a2df047c0e17"

RUN apk add --no-cache php7-pecl-imagick optipng pngquant jpegoptim gifsicle postgresql-dev \
  sqlite-dev zip unzip libzip-dev curl-dev freetype icu-dev libjpeg-turbo libpng libwebp \
  freetype-dev libjpeg-turbo-dev libxpm libxpm-dev libwebp-dev git

RUN docker-php-source extract
RUN docker-php-ext-configure gd --enable-freetype \
  --with-jpeg-dir=/usr/lib/ \
  --with-xpm-dir=/usr/lib/ \
  --with-webp-dir=/usr/lib/

RUN docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite pcntl gd exif bcmath intl zip curl && \
  docker-php-ext-enable pcntl gd exif zip curl

RUN curl -LsS https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar \
  -o /usr/bin/composer && \
  echo "${COMPOSER_CHECKSUM}  /usr/bin/composer" | sha256sum -c - && \
  chmod 755 /usr/bin/composer

RUN docker-php-source delete

ENV PATH="~/.composer/vendor/bin:./vendor/bin:${PATH}"

RUN git clone https://github.com/pixelfed/pixelfed /var/www/pixelfed
WORKDIR /var/www/

RUN cp -a pixelfed/* .
RUN mkdir public.ext && cp -r storage storage.skel
RUN cp contrib/docker/php.ini /usr/local/etc/php/conf.d/pixelfed.ini
RUN composer install --prefer-dist --no-interaction
RUN rm -rf html && ln -s public html

VOLUME /var/www/storage

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    BROADCAST_DRIVER=log \
    QUEUE_DRIVER=redis \
    HORIZON_PREFIX=horizon-pixelfed \
    SESSION_SECURE_COOKIE=true \
    API_BASE="/api/1/" \
    API_SEARCH="/api/search" \
    ENFORCE_EMAIL_VERIFICATION=true \
    REMOTE_FOLLOW=true \
    ACTIVITY_PUB=true

COPY init.sh /init.sh
COPY zz-docker.conf /usr/local/etc/php-fpm.d/
RUN chmod 0555 /init.sh
CMD /init.sh
