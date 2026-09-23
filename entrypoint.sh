#!/bin/bash
set -e

PORT="${PORT:-10000}"

# Replace port placeholder in Apache configs
sed -i "s/__PORT__/${PORT}/g" /etc/apache2/ports.conf
sed -i "s/__PORT__/${PORT}/g" /etc/apache2/sites-available/000-default.conf

# Configure Dolibarr database from Render's DATABASE_URL
if [ -n "$DATABASE_URL" ]; then
    DB_USER=$(echo "$DATABASE_URL" | sed -n 's|.*://\([^:]*\):.*|\1|p')
    DB_PASS=$(echo "$DATABASE_URL" | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
    DB_HOST=$(echo "$DATABASE_URL" | sed -n 's|.*@\([^:]*\):.*|\1|p')
    DB_PORT=$(echo "$DATABASE_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DATABASE_URL" | sed -n 's|.*/\([^/?]*\).*|\1|p')

    cat > /var/www/html/dolibarr/htdocs/conf/conf.php << EOF
<?php
\$dolibarr_main_url_root='${DOLIBARR_URL_ROOT:-http://localhost}';
\$dolibarr_main_document_root='/var/www/html/dolibarr/htdocs';
\$dolibarr_main_data_root='/var/www/html/dolibarr/documents';
\$dolibarr_main_db_type='pgsql';
\$dolibarr_main_db_host='$DB_HOST';
\$dolibarr_main_db_port='$DB_PORT';
\$dolibarr_main_db_name='$DB_NAME';
\$dolibarr_main_db_user='$DB_USER';
\$dolibarr_main_db_pass='$DB_PASS';
\$dolibarr_main_db_prefix='llx_';
\$dolibarr_main_db_character_set='UTF8';
\$dolibarr_main_db_collation='';
\$dolibarr_main_authentication='dolibarr';
\$dolibarr_main_instance_unique_id='$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)';
\$dolibarr_main_distrib='standard';
EOF

    chown www-data:www-data /var/www/html/dolibarr/htdocs/conf/conf.php
    echo "Dolibarr conf.php configured"
fi

exec "$@"