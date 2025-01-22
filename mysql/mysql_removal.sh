#!/bin/bash

# Remove MySQL packages and purge configuration files
echo "Removing MySQL server, client, and common packages..."
sudo apt-get remove --purge mysql-server mysql-client mysql-common -y

# Remove unused packages
echo "Removing unused packages..."
sudo apt-get autoremove -y

# Clean up package cache
echo "Cleaning up package cache..."
sudo apt-get autoclean

# Remove MySQL APT configuration package
echo "Removing MySQL APT configuration..."
sudo apt-get remove mysql-apt-config -y
sudo apt-get purge mysql-apt-config -y

# Clear APT lists
echo "Clearing APT lists..."
sudo rm -rf /var/lib/apt/lists/*

# Reboot the system
echo "Rebooting the system..."
sudo reboot
