#!/bin/bash

# Service name
SERVICE="apache2"

# Check if Apache is installed using dpkg-query
dpkg_query_status=$(dpkg-query -W -f='${Status}' $SERVICE 2>/dev/null | grep "install ok installed")

if [ "$dpkg_query_status" ]; then
    echo "The service $SERVICE is already installed."
    echo "Displaying the status of the $SERVICE service:"
    sudo systemctl status $SERVICE
else
    echo "The service $SERVICE is not installed. Installing now..."
    sudo apt update && sudo apt install -y $SERVICE

    if [ $? -eq 0 ]; then
        echo "$SERVICE has been successfully installed."
        echo "Starting the $SERVICE service..."
        sudo systemctl start $SERVICE
        echo "$SERVICE service has been started."
        echo "Enabling $SERVICE to start on boot..."
        sudo systemctl enable $SERVICE
    else
        echo "Failed to install $SERVICE. Please check your package manager or internet connection."
    fi
fi
