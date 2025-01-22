#!/bin/bash

# Define variables
MYSQL_PACKAGE="mysql-server"
MYSQL_CLIENT_PACKAGE="mysql-client"
MYSQL_COMMON_PACKAGE="mysql-common"
MYSQL_REPO_URL="https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb"
MYSQL_REPO_DEB="mysql-apt-config.deb"
MYSQL_ROOT_PASSWORD="qwerty"  # Set root password to 'qwerty'

# Function to check if a package is installed
is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Function to add MySQL GPG key if missing
add_mysql_gpg_key() {
    echo "Adding MySQL GPG key..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B7B3B788A8D3785C || {
        echo "Failed to add GPG key. Attempting to download and install MySQL APT config..."
        wget -O "$MYSQL_REPO_DEB" "$MYSQL_REPO_URL" || { echo "Failed to download MySQL APT config. Exiting."; exit 1; }
        sudo dpkg -i "$MYSQL_REPO_DEB" || { echo "Failed to configure MySQL APT repository. Exiting."; exit 1; }
    }
}

# Preconfigure MySQL APT repository settings
preconfigure_mysql_repo() {
    echo "Preconfiguring MySQL APT repository..."
    echo "mysql-apt-config mysql-apt-config/select-product select Ok" | sudo debconf-set-selections
    echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.0" | sudo debconf-set-selections
    echo "mysql-apt-config mysql-apt-config/select-tools select Enabled" | sudo debconf-set-selections
    echo "mysql-apt-config mysql-apt-config/select-preview select Disabled" | sudo debconf-set-selections
}

# Remove conflicting or unnecessary MySQL packages and repositories only if errors occur
remove_conflicting_packages() {
    echo "Checking for conflicting MySQL packages and removing them if necessary..."
    sudo apt-get remove --purge -y "$MYSQL_PACKAGE" "$MYSQL_CLIENT_PACKAGE" "$MYSQL_COMMON_PACKAGE" || echo "Some packages could not be removed. Continuing..."
    sudo apt-get autoremove -y || echo "Failed to autoremove unnecessary packages."
    sudo apt-get autoclean || echo "Failed to clean up package cache."
}

# Install MySQL server
install_mysql() {
    echo "Updating package list and upgrading installed packages..."
    sudo apt update && sudo apt upgrade -y

    add_mysql_gpg_key

    # Preconfigure the MySQL APT repository settings
    preconfigure_mysql_repo

    # Update package list after adding the repository
    echo "Updating package list..."
    sudo apt update || { echo "Failed to update package list. Attempting to fix issues..."; sudo apt-get -f install -y; }

    # Install MySQL server
    echo "Installing MySQL server..."
    export DEBIAN_FRONTEND=noninteractive
    if sudo apt install -y "$MYSQL_PACKAGE"; then
        echo "MySQL server has been installed successfully."
        secure_mysql
        notify_success
    else
        echo "Failed to install MySQL server. Attempting to fix issues and retry..."
        remove_conflicting_packages
        sudo apt update && sudo apt install -y "$MYSQL_PACKAGE" || { echo "MySQL installation failed again. Exiting."; exit 1; }
        secure_mysql
        notify_success
    fi
}

# Secure MySQL installation
secure_mysql() {
    echo "Securing MySQL installation..."
    
    SECURE_MYSQL=$(expect -c "
    set timeout 10
    spawn mysql_secure_installation
    expect \"Enter current password for root (enter for none):\"
    send \"$MYSQL_ROOT_PASSWORD\r\"
    expect \"Set root password? [Y/n]\"
    send \"y\r\"
    expect \"New password:\"
    send \"$MYSQL_ROOT_PASSWORD\r\"
    expect \"Re-enter new password:\"
    send \"$MYSQL_ROOT_PASSWORD\r\"
    expect \"Remove anonymous users?\"
    send \"y\r\"
    expect \"Disallow root login remotely?\"
    send \"y\r\"
    expect \"Remove test database and access to it?\"
    send \"y\r\"
    expect \"Reload privilege tables now?\"
    send \"y\r\"
   expect eof
   ")
    
   echo "$SECURE_MYSQL"
}

# Notify successful installation
notify_success() {
   echo "MySQL server installation and configuration completed successfully!"
}

# Configure MySQL client settings in ~/.my.cnf
configure_mysql_client() {
   echo "Configuring MySQL client for root user..."
   local MYSQL_CNF="$HOME/.my.cnf"

   if [ ! -f "$MYSQL_CNF" ]; then
       touch "$MYSQL_CNF"  # Create the .my.cnf file if it doesn't exist.
       {
           echo "[client]"
           echo "host=localhost"
           echo "user=root"
           echo "password=$MYSQL_ROOT_PASSWORD"  # Use the defined root password.
       } >> "$MYSQL_CNF"

       chmod 600 "$MYSQL_CNF"  # Set permissions for security.
       echo "MySQL client configuration created at $MYSQL_CNF."
   else
       echo "MySQL client configuration already exists at $MYSQL_CNF."
   fi
}

# Check if MySQL is already installed
check_mysql() {
   MYSQL_INSTALLED=$(is_package_installed "$MYSQL_PACKAGE")

   if [ "$MYSQL_INSTALLED" ]; then
       echo "MySQL server is already installed."
       echo "Checking MySQL service status..."
       sudo systemctl status mysql || echo "MySQL service is not running. Please start it with: sudo systemctl start mysql"
   else
       echo "MySQL server is not installed. Proceeding with installation."
       install_mysql
   fi
}

# Main script execution
check_mysql

# Final status message
echo "Script execution completed."
