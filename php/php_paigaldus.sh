#!/bin/bash

# Update package list and upgrade installed packages
echo "Updating package list and upgrading installed packages..."
sudo apt update && sudo apt upgrade -y

# Determine the PHP version dynamically for Debian 11 Bullseye
PHP_VERSION=$(apt-cache show php | grep -oP 'Version: \K[0-9]+\.[0-9]+' | head -n 1)
PHP_PACKAGE="php"
LIBAPACHE_PACKAGE="libapache2-mod-php$PHP_VERSION"
PHP_MYSQL_PACKAGE="php$PHP_VERSION-mysql"

# Function to check if a package is installed
is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Function to check for journal errors and fix them
fix_journal_errors() {
    echo "Checking journal for errors..."
    # Check for corrupted journal files
    corrupted_files=$(journalctl --verify | grep 'File corruption detected at' | awk '{print $NF}')
    
    if [ -n "$corrupted_files" ]; then
        echo "Corrupted journal files detected:"
        echo "$corrupted_files"
        echo "Removing corrupted journal files..."
        echo "$corrupted_files" | xargs sudo rm -f
        echo "Corrupted files have been removed."
    else
        echo "No corrupted journal files found."
    fi
}

# Install PHP and necessary packages
install_php_packages() {
    echo "Installing PHP and necessary packages..."
    if sudo apt install -y "$PHP_PACKAGE" "$LIBAPACHE_PACKAGE" "$PHP_MYSQL_PACKAGE"; then
        echo "PHP and necessary packages have been successfully installed."
        configure_php
    else
        echo "Failed to install PHP and necessary packages. Attempting to install PHP 7.4 as a fallback..."
        sudo apt install -y php7.4 libapache2-mod-php7.4 php7.4-mysql
        configure_php "7.4"
    fi
}

# Configure PHP for the web server
configure_php() {
    local version=${1:-$PHP_VERSION}
    echo "Configuring PHP $version for the web server..."
    
    # Check if the PHP module is enabled, if not, attempt to fix it
    if ! sudo a2enmod php$version; then
        echo "PHP module for Apache does not exist. Attempting to enable PHP $version module..."
        
        # Enable the PHP module for Apache
        if sudo apt install -y libapache2-mod-php$version; then
            sudo a2enmod php$version
            echo "Successfully enabled PHP $version module for Apache."
        else
            echo "Failed to install or enable PHP $version module for Apache."
            exit 1
        fi
    else
        echo "PHP module for Apache has been enabled."
    fi
    
    # Restart Apache to apply changes
    if sudo systemctl restart apache2; then
        echo "Apache has been restarted. PHP is now configured to work with the web server."
    else
        echo "Failed to restart Apache. Please check the service logs."
        exit 1
    fi
}

# Check if PHP is installed and configured correctly
if is_package_installed "$PHP_PACKAGE" && is_package_installed "$LIBAPACHE_PACKAGE" && is_package_installed "$PHP_MYSQL_PACKAGE"; then
    echo "PHP and necessary packages are already installed."
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

# Check journal logs for any errors (optional)
fix_journal_errors

echo "Checking journal logs for any remaining errors..."
sudo journalctl -xe | tail -n 20
