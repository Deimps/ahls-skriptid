#!/bin/sh

# WordPress installation script
# Author: [Deimo]
# Date: [28.01.2025]

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run the script as root."
  exit 1
fi

# Variables
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASSWORD="qwerty"
DB_HOST="localhost"
WP_DOWNLOAD_URL="https://wordpress.org/latest.tar.gz"
WP_DIR="/var/www/html/wordpress"
WP_CONFIG_FILE="$WP_DIR/wp-config.php"

# Check if a service is installed
check_service_installed() {
  if ! dpkg -l | grep -qw "$1"; then
    echo "$1 is not installed. Installing..."
    apt update
    if apt install -y "$1"; then
      echo "$1 successfully installed."
    else
      echo "Error: Failed to install $1." >&2
      exit 1
    fi
  else
    echo "$1 is already installed."
  fi
}

# Check required services
check_service_installed apache2
check_service_installed php
check_service_installed php-mysql
check_service_installed mysql-server
check_service_installed wget

# Start services and enable them
for service in apache2 mysql; do
  if ! systemctl start "$service"; then
    echo "Error: Failed to start $service." >&2
    exit 1
  fi
  systemctl enable "$service"
done

# Create database and user
cat <<EOF | mysql -u root
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST';
FLUSH PRIVILEGES;
EOF

# Download and install WordPress
if [ ! -d "$WP_DIR" ]; then
  echo "Downloading WordPress..."
  wget -q "$WP_DOWNLOAD_URL" -O /tmp/latest.tar.gz

  echo "Extracting WordPress..."
  tar -xzf /tmp/latest.tar.gz -C /tmp

  echo "Installing WordPress..."
  mv /tmp/wordpress "$WP_DIR"
  chown -R www-data:www-data "$WP_DIR"
  chmod -R 755 "$WP_DIR"
else
  echo "WordPress is already installed."
fi

# Configure wp-config.php
if [ ! -f "$WP_CONFIG_FILE" ]; then
  cp "$WP_DIR/wp-config-sample.php" "$WP_CONFIG_FILE"
  sed -i "s/database_name_here/$DB_NAME/" "$WP_CONFIG_FILE"
  sed -i "s/username_here/$DB_USER/" "$WP_CONFIG_FILE"
  sed -i "s/password_here/$DB_PASSWORD/" "$WP_CONFIG_FILE"
  sed -i "s/localhost/$DB_HOST/" "$WP_CONFIG_FILE"
  echo "Configured wp-config.php."
else
  echo "wp-config.php already exists."
fi

# Check if WordPress is accessible
echo "WordPress should now be accessible at: http://$(hostname -I | awk '{print $1}')/wordpress"

# Completion
echo "WordPress installation complete."
