<?php
// Resets the admin user password to a known value.
// Uses Dolibarr's conf.php for DB credentials.
// Controlled by DOLIBARR_ADMIN_PASSWORD env var.

$conf_file = '/var/www/html/dolibarr/htdocs/conf/conf.php';
if (!file_exists($conf_file)) {
    echo "conf.php not found, skipping admin reset\n";
    exit(0);
}

include $conf_file;

$new_password = getenv('DOLIBARR_ADMIN_PASSWORD');
if (empty($new_password)) {
    echo "DOLIBARR_ADMIN_PASSWORD not set, skipping admin reset\n";
    exit(0);
}

$prefix = isset($dolibarr_main_db_prefix) ? $dolibarr_main_db_prefix : 'llx_';

try {
    $dsn = "pgsql:host={$dolibarr_main_db_host};port={$dolibarr_main_db_port};dbname={$dolibarr_main_db_name}";
    $pdo = new PDO($dsn, $dolibarr_main_db_user, $dolibarr_main_db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 10,
    ]);

    // Check if the user table exists (fresh DB -> let web installer handle it)
    $tbl = $prefix . 'user';
    $check = $pdo->query("SELECT to_regclass('{$tbl}')");
    $exists = $check->fetchColumn();
    if (!$exists) {
        echo "Table {$tbl} does not exist yet — fresh install, skipping reset (web installer will run)\n";
        exit(0);
    }

    $hash = md5($new_password);

    $stmt = $pdo->prepare("UPDATE {$tbl} SET pass_crypted = :h, pass = :h WHERE login = 'admin'");
    $stmt->execute([':h' => $hash]);

    if ($stmt->rowCount() > 0) {
        echo "Admin password reset successfully\n";
    } else {
        echo "Admin user not found — web installer will create it\n";
    }
} catch (Exception $e) {
    echo "Reset failed (will rely on web installer): " . $e->getMessage() . "\n";
}
