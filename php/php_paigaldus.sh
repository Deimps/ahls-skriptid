#!/bin/bash

# Determine the PHP version dynamically for Debian 11 Bullseye
PHP_VERSION=$(apt-cache show php | grep -oP 'Version: \K[0-9]+\.[0-9]+' | head -n 1)
PHP_PACKAGE="php"
LIBAPACHE_PACKAGE="libapache2-mod-php$PHP_VERSION"
PHP_MYSQL_PACKAGE="php$PHP_VERSION-mysql"

# Function to check if a package is installed
is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Install PHP and necessary packages
install_php_packages() {
    echo "Installing PHP and necessary packages..."
    sudo apt update
    if sudo apt install -y "$PHP_PACKAGE" "$LIBAPACHE_PACKAGE" "$PHP_MYSQL_PACKAGE"; then
        echo "PHP and necessary packages have been successfully installed."
        configure_php
    else
        echo "Failed to install PHP and necessary packages. Please check your package manager or internet connection."
        exit 1
    fi
}

# Configure PHP for the web server
configure_php() {
    echo "Configuring PHP for the web server..."
    if sudo a2enmod php$PHP_VERSION; then
        echo "PHP module for Apache has been enabled."
        echo "Restarting Apache to apply changes..."
        if sudo systemctl restart apache2; then
            echo "Apache has been restarted. PHP is now configured to work with the web server."
        else
            echo "Failed to restart Apache. Please check the service logs."
            exit 1
        fi
    else
        echo "Failed to enable PHP module for Apache. Please check the configuration."
        exit 1
    fi
}

# Check if PHP is installed
if is_package_installed "$PHP_PACKAGE" && is_package_installed "$LIBAPACHE_PACKAGE" && is_package_installed "$PHP_MYSQL_PACKAGE"; then
    echo "PHP and necessary packages are already installed."
    echo "Displaying the status of the Apache service to ensure proper integration:"
    sudo systemctl is-active apache2 && echo "Apache is active." || echo "Apache is not running."
    sudo systemctl is-enabled apache2 && echo "Apache is enabled to start on boot." || echo "Apache is not enabled to start on boot."
else
    echo "PHP or necessary packages are not installed. Proceeding with installation."
    install_php_packages
fi

# Display PHP version and status
php_version_installed=$(php -v | head -n 1 | awk '{print $2}')
if [ "$php_version_installed" ]; then
    echo "PHP version $php_version_installed is installed."
else
    echo "PHP installation or detection failed."
fi

# Final status of the Apache service
echo "Final status of the Apache service:"
sudo systemctl is-active apache2 && echo "Apache is active." || echo "Apache is not running."
sudo systemctl is-enabled apache2 && echo "Apache is enabled to start on boot." || echo "Apache is not enabled to start on boot."
