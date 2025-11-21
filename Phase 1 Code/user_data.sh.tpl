#!/bin/bash
set -euxo pipefail

# Log user-data output to a file and the console
exec > >(tee /var/log/enpm818n-userdata.log | logger -t user-data -s 2>/dev/console) 2>&1

export DEBIAN_FRONTEND=noninteractive

APP_DIR="/var/www/html"
TEMP_DIR="/tmp/ecommerce_app"

# Helper: wait for apt/dpkg locks (cloud-init sometimes runs apt in parallel)
wait_for_apt() {
  local tries=0
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -gt 30 ]; then
      echo "apt locks not released after $tries tries" >&2
      break
    fi
    echo "Waiting for apt/dpkg lock..."
    sleep 5
  done
}

wait_for_apt
apt-get update -y

# --- SSM agent (for Session Manager) ---
snap install amazon-ssm-agent --classic || true
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# --- Apache, PHP, Git, etc. ---
apt-get install -y apache2 php libapache2-mod-php php-mysql git curl rsync

systemctl enable apache2
systemctl restart apache2

# Prioritize index.php over index.html
if [ -f /etc/apache2/mods-enabled/dir.conf ]; then
  sed -i 's/DirectoryIndex .*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' \
    /etc/apache2/mods-enabled/dir.conf
  systemctl restart apache2
fi

# --- Deploy the ENPM818N app from GitHub ---
mkdir -p "${APP_DIR}"

rm -rf "${TEMP_DIR}"
git clone "${github_repo_url}" "${TEMP_DIR}"

# Remove default Apache welcome page
rm -f "${APP_DIR}/index.html"

# Copy project files into web root
rsync -a --delete "${TEMP_DIR}/" "${APP_DIR}/"

mkdir -p "${APP_DIR}/includes"

# --- Healthcheck endpoint for ALB ---
cat > "${APP_DIR}/healthcheck.php" << 'PHP'
<?php
http_response_code(200);
echo "OK - enpm818n healthcheck";
PHP

# --- RDS DB connection for the app ---
cat > "${APP_DIR}/includes/connect.php" << PHP
<?php
\$servername = "${db_endpoint}";
\$username   = "${db_username}";
\$password   = "${db_password}";
\$dbname     = "${db_name}";

\$con = mysqli_connect(\$servername, \$username, \$password, \$dbname);

if (!\$con) {
    die("Connection failed: " . mysqli_connect_error());
}
?>
PHP

# Permissions
chown -R www-data:www-data "${APP_DIR}"
find "${APP_DIR}" -type d -exec chmod 755 {} \;
find "${APP_DIR}" -type f -exec chmod 644 {} \;

systemctl restart apache2
