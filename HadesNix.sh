#!/bin/bash

echo "Welcome to NixOS One installation."
echo "Please select your language:"
echo "1. Bahasa Indonesia"
echo "2. English"
read -p "Enter your choice (1/2): " choice

case $choice in
  1)
    echo "You have chosen Bahasa Indonesia."
    echo "Starting installation process..."
    curl -o install.sh https://raw.githubusercontent.com/bangundwir/NixosOneInstall/main/id.install.sh
    chmod +x install.sh
    ./install.sh
    ;;
  2)
    echo "You have selected English."
    echo "Starting installation process..."
    curl -o install.sh https://raw.githubusercontent.com/bangundwir/NixosOneInstall/main/en.install.sh
    chmod +x install.sh
    ./install.sh
    ;;
  *)
    echo "Invalid choice. Please choose 1 or 2."
    ;;
esac
