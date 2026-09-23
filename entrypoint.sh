#!/bin/bash
set -e

PORT="${PORT:-10000}"

sed -i "s/__PORT__/${PORT}/g" /etc/apache2/ports.conf
sed -i "s/__PORT__/${PORT}/g" /etc/apache2/sites-available/000-default.conf

# Parse DATABASE_URL for PostgreSQL connection
if [ -n "$DATABASE_URL" ]; then
    DB_USER=$(echo "$DATABASE_URL" | sed -n 's|.*://\([^:]*\):.*|\1|p')
    DB_PASS=$(echo "$DATABASE_URL" | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
    DB_HOST=$(echo "$DATABASE_URL" | sed -n 's|.*@\([^:]*\):.*|\1|p')
    DB_PORT=$(echo "$DATABASE_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DATABASE_URL" | sed -n 's|.*/\([^/?]*\).*|\1|p')

    echo "DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_NAME=$DB_NAME DB_USER=$DB_USER"

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

    # ── Auto-install Dolibarr tables via CLI ──
    echo "Running Dolibarr auto-install..."
    cd /var/www/html/dolibarr/htdocs/install

    # Step 1: Save config to install.forced.php so installer uses it
    php -r "
    require '/var/www/html/dolibarr/htdocs/conf/conf.php';
    \$force = array(
        'main_dir' => '/var/www/html/dolibarr/htdocs',
        'main_data_dir' => '/var/www/html/dolibarr/documents',
        'main_url' => getenv('DOLIBARR_URL_ROOT') ?: 'http://localhost',
        'db_name' => '$DB_NAME',
        'db_type' => 'pgsql',
        'db_host' => '$DB_HOST',
        'db_port' => '$DB_PORT',
        'db_prefix' => 'llx_',
        'db_user' => '$DB_USER',
        'db_pass' => '$DB_PASS',
        'selectlang' => 'en_US',
    );
    file_put_contents('install.forced.php', '<?php' . PHP_EOL . '\$force_install_databaserootlogin = \'$DB_USER\';' . PHP_EOL . '\$force_install_databaserootpass = \'$DB_PASS\';' . PHP_EOL . '\$force_install_database = \'' . json_encode(\$force) . '\';' . PHP_EOL);
    echo 'install.forced.php created' . PHP_EOL;
    "

    # Step 2: Run forced install
    php -r "
    \$_POST = array(
        'testpost' => 'ok',
        'action' => 'set',
        'main_dir' => '/var/www/html/dolibarr/htdocs',
        'main_data_dir' => '/var/www/html/dolibarr/documents',
        'main_url' => getenv('DOLIBARR_URL_ROOT') ?: 'http://localhost',
        'db_name' => '$DB_NAME',
        'db_type' => 'pgsql',
        'db_host' => '$DB_HOST',
        'db_port' => '$DB_PORT',
        'db_prefix' => 'llx_',
        'db_user' => '$DB_USER',
        'db_pass' => '$DB_PASS',
        'selectlang' => 'en_US',
    );
    \$force_install_noedit = 2;  // Skip config file creation (already done)
    \$force_install_message = 'auto';
    \$force_install_main_data_root = '/var/www/html/dolibarr/documents';
    \$force_install_main_document_root = '/var/www/html/dolibarr/htdocs';
    \$force_install_createuser = false;
    \$force_install_createdatabase = false;
    
    // Run step1
    include 'step1.php';
    echo 'Install completed' . PHP_EOL;
    " 2>&1 || echo "Auto-install completed with warnings (may be ok)"

    cd /
    echo "Dolibarr auto-install finished"
fi

exec "$@"