FROM php:8.2-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libicu-dev unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg 2>/dev/null || true \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql pgsql gd zip intl calendar mysqli pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

ENV DOLIBARR_VERSION=20.0.3
RUN curl -fsSL "https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz" \
    | tar xz -C /var/www/ \
    && mv "/var/www/dolibarr-${DOLIBARR_VERSION}" /var/www/html/dolibarr \
    && mkdir -p /var/www/html/dolibarr/documents \
    && chown -R www-data:www-data /var/www/html/dolibarr \
    && cp /var/www/html/dolibarr/htdocs/conf/conf.php.example /var/www/html/dolibarr/htdocs/conf/conf.php \
    && chown www-data:www-data /var/www/html/dolibarr/htdocs/conf/conf.php

COPY apache-ports.conf /etc/apache2/ports.conf
COPY apache-site.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 10000

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]