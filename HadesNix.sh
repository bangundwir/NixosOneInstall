#!/bin/bash

echo -ne "
--------------------------------------------------------------------
██╗░░██╗░█████╗░██████╗░███████╗░██████╗███╗░░██╗██╗██╗░░██╗
██║░░██║██╔══██╗██╔══██╗██╔════╝██╔════╝████╗░██║██║╚██╗██╔╝
███████║███████║██║░░██║█████╗░░╚█████╗░██╔██╗██║██║░╚███╔╝░
██╔══██║██╔══██║██║░░██║██╔══╝░░░╚═══██╗██║╚████║██║░██╔██╗░
██║░░██║██║░░██║██████╔╝███████╗██████╔╝██║░╚███║██║██╔╝╚██╗
╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝╚═════╝░╚═╝░░╚══╝╚═╝╚═╝░░╚═╝
------------------------------------------------------------------
                    Automated NixOs Installer
-------------------------------------------------------------------
                Scripts are in directory named HadesNixOs
"

echo "Welcome to NixOS One installation."
echo "Please select your language:"
echo "1. Bahasa Indonesia"
echo "2. English"
read -p "Enter your choice (1/2): " choice

case $choice in
  1)
    echo "You have chosen Bahasa Indonesia."
    echo "Starting installation process..."
    if curl -o install.sh https://raw.githubusercontent.com/bangundwir/NixosOneInstall/main/id.install.sh && chmod +x install.sh && ./install.sh; then
        echo "Installation completed successfully."
    else
        echo "Error occurred during installation."
    fi
    ;;
  2)
    echo "You have selected English."
    echo "Starting installation process..."
    if curl -o install.sh https://raw.githubusercontent.com/bangundwir/NixosOneInstall/main/en.install.sh && chmod +x install.sh && ./install.sh; then
        echo "Installation completed successfully."
    else
        echo "Error occurred during installation."
    fi
    ;;
  *)
    echo "Invalid choice. Please choose 1 or 2."
    echo "Starting default installation process..."
    if curl -o install.sh https://raw.githubusercontent.com/bangundwir/NixosOneInstall/main/default.sh && chmod +x install.sh && ./install.sh; then
        echo "Installation completed successfully."
    else
        echo "Error occurred during installation."
    fi
    ;;
esac
