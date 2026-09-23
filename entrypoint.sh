#!/bin/bash
set -e

PORT="${PORT:-10000}"

sed -i "s/__PORT__/${PORT}/g" /etc/apache2/ports.conf
sed -i "s/__PORT__/${PORT}/g" /etc/apache2/sites-available/000-default.conf

if [ -n "$DATABASE_URL" ]; then
    DB_USER=$(echo "$DATABASE_URL" | sed -n 's|.*://\([^:]*\):.*|\1|p')
    DB_PASS=$(echo "$DATABASE_URL" | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
    DB_HOST=$(echo "$DATABASE_URL" | sed -n 's|.*@\([^:]*\):.*|\1|p')
    DB_PORT=$(echo "$DATABASE_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DATABASE_URL" | sed -n 's|.*/\([^/?]*\).*|\1|p')

    DOLIBARR_URL="${DOLIBARR_URL_ROOT:-http://localhost}"

    cat > /var/www/html/dolibarr/htdocs/conf/conf.php << EOF
<?php
\$dolibarr_main_url_root='$DOLIBARR_URL';
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
    echo "[entrypoint] conf.php written for DB: $DB_HOST:$DB_PORT/$DB_NAME"

    # ── Auto-install: submit Dolibarr installer via curl ──
    INSTALL_URL="${DOLIBARR_URL}/install"
    echo "[entrypoint] Waiting for Apache..."
    sleep 2

    # Step 1: fileconf → step1 (save config, no db/user creation)
    echo "[entrypoint] Step 1: Saving config..."
    STEP1_RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST "${INSTALL_URL}/step1.php" \
      -d "testpost=ok" \
      -d "action=set" \
      -d "main_dir=/var/www/html/dolibarr/htdocs" \
      -d "main_data_dir=/var/www/html/dolibarr/documents" \
      -d "main_url=${DOLIBARR_URL}" \
      -d "db_name=${DB_NAME}" \
      -d "db_type=pgsql" \
      -d "db_host=${DB_HOST}" \
      -d "db_port=${DB_PORT}" \
      -d "db_prefix=llx_" \
      -d "db_user=${DB_USER}" \
      -d "db_pass=${DB_PASS}" \
      -d "selectlang=en_US")
    echo "[entrypoint] Step 1 HTTP: ${STEP1_RESULT}"

    # Step 2: step2 → step5 (create DB structure)
    if [ "$STEP1_RESULT" = "200" ]; then
        echo "[entrypoint] Step 2: Creating database structure..."
        STEP2_RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
          -X POST "${INSTALL_URL}/step5.php" \
          -d "testpost=ok" \
          -d "action=set" \
          -d "selectlang=en_US")
        echo "[entrypoint] Step 2 HTTP: ${STEP2_RESULT}"
    fi

    echo "[entrypoint] Auto-install complete"
fi

exec "$@"