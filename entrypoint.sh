#!/bin/bash
set -e

PORT="${PORT:-10000}"

sed -i "s/__PORT__/${PORT}/g" /etc/apache2/ports.conf
sed -i "s/__PORT__/${PORT}/g" /etc/apache2/sites-available/000-default.conf

if [ -n "$DOLIBARR_DB_HOST" ]; then
    cat > /var/www/html/dolibarr/htdocs/conf/conf.php << EOF
<?php
\$dolibarr_main_url_root='${DOLIBARR_URL_ROOT:-http://localhost}';
\$dolibarr_main_document_root='/var/www/html/dolibarr/htdocs';
\$dolibarr_main_data_root='/var/www/html/dolibarr/documents';
\$dolibarr_main_db_type='pgsql';
\$dolibarr_main_db_host='$DOLIBARR_DB_HOST';
\$dolibarr_main_db_port='$DOLIBARR_DB_PORT';
\$dolibarr_main_db_name='$DOLIBARR_DB_NAME';
\$dolibarr_main_db_user='$DOLIBARR_DB_USER';
\$dolibarr_main_db_pass='$DOLIBARR_DB_PASS';
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