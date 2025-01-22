#!/bin/bash

# Define the phpMyAdmin package name and version
PMA_PACKAGE="phpmyadmin"
PMA_REPO_URL="https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.zip"
PMA_REPO_DEB="phpMyAdmin-5.1.1-all-languages.zip"

# Function to check if a package is installed
is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Install necessary PHP extensions for phpMyAdmin
install_php_extensions() {
    echo "Installing necessary PHP extensions for phpMyAdmin..."
    sudo apt install -y php-mbstring php-zip php-gd || { echo "Failed to install PHP extensions. Exiting."; exit 1; }
}

# Install phpMyAdmin
install_phpmyadmin() {
    # Check if phpMyAdmin is already installed
    PMA=$(dpkg-query -W -f='${Status}' phpmyadmin 2>/dev/null | grep -c 'ok installed')
    
    if [ $PMA -eq 0 ]; then
        echo "Installing phpMyAdmin and necessary support packages..."
        
        # Install PHP extensions required by phpMyAdmin
        install_php_extensions
        
        # Download phpMyAdmin
        wget -O "$PMA_REPO_DEB" "$PMA_REPO_URL" || { echo "Failed to download phpMyAdmin. Exiting."; exit 1; }
        
        # Unzip the downloaded file (ensure unzip is installed)
        if ! command -v unzip &> /dev/null; then
            echo "Unzip is not installed. Installing unzip..."
            sudo apt install -y unzip || { echo "Failed to install unzip. Exiting."; exit 1; }
        fi
        
        unzip "$PMA_REPO_DEB" || { echo "Failed to unzip phpMyAdmin package. Exiting."; exit 1; }
        
        # Move the extracted directory to the appropriate location
        sudo mv phpMyAdmin-5.1.1-all-languages /usr/share/phpmyadmin
        
        # Create a temporary directory for phpMyAdmin
        sudo mkdir -p /var/lib/phpmyadmin/tmp
        
        # Set proper ownership for the phpMyAdmin directory
        sudo chown -R www-data:www-data /usr/share/phpmyadmin
        
        # Copy sample configuration file
        sudo cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php
        
        echo "phpMyAdmin has been installed successfully."
        
    elif [ $PMA -eq 1 ]; then
        echo "phpMyAdmin is already installed."
    else
        echo "Unexpected error occurred while checking phpMyAdmin installation."
    fi
}

# Main script execution
echo "Starting installation of phpMyAdmin..."
install_phpmyadmin

# Final status of the phpMyAdmin service (optional)
echo "Checking final status of Apache service..."
sudo systemctl is-active apache2 && echo "Apache service is active." || echo "Apache service is not running."

echo "Script execution completed."
