#!/bin/sh
#
# Script for installing NixOS after booting from the minimal USB image.
#
# To run:
#
#     sh -c "$(curl https://url.dwirz.my.id/nixos.sh)"
#
# 
echo -ne "
------------------------------------------------------------------------------------------------
$$\   $$\                 $$\                     $$\   $$\ $$\            $$$$$$\            
$$ |  $$ |                $$ |                    $$$\  $$ |\__|          $$  __$$\           
$$ |  $$ | $$$$$$\   $$$$$$$ | $$$$$$\   $$$$$$$\ $$$$\ $$ |$$\ $$\   $$\ $$ /  $$ | $$$$$$$\ 
$$$$$$$$ | \____$$\ $$  __$$ |$$  __$$\ $$  _____|$$ $$\$$ |$$ |\$$\ $$  |$$ |  $$ |$$  _____|
$$  __$$ | $$$$$$$ |$$ /  $$ |$$$$$$$$ |\$$$$$$\  $$ \$$$$ |$$ | \$$$$  / $$ |  $$ |\$$$$$$\  
$$ |  $$ |$$  __$$ |$$ |  $$ |$$   ____| \____$$\ $$ |\$$$ |$$ | $$  $$<  $$ |  $$ | \____$$\ 
$$ |  $$ |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ $$$$$$$  |$$ | \$$ |$$ |$$  /\$$\  $$$$$$  |$$$$$$$  |
\__|  \__| \_______| \_______| \_______|\_______/ \__|  \__|\__|\__/  \__| \______/ \_______/
------------------------------------------------------------------------------------------------
                    Automated NixOs Installer
-------------------------------------------------------------------------
                Scripts are in directory named HadesNixOs
"

echo "--------------------------------------------------------------------------------"
echo "Here is the list of attached storage devices."
read -p "Press 'q' to exit the list. Press enter to continue." NULL

# Displaying the list of attached storage devices
sudo fdisk -l | less

echo "--------------------------------------------------------------------------------"
echo "Detected devices:"
echo

# Storing the list of detected storage devices
declare -a DEVICES
i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
    echo "[$i] $device"
    DEVICES[$i]=$device
    i=$((i+1))
done

echo
read -p "Which device do you want to install on? Enter the device number: " DEVICE

# Selecting the device for installation
DEV=${DEVICES[$DEVICE]}

# Asking the user to input the desired swap space size
read -p "How much swap space do you need in GiB (e.g. 8)? " SWAP

# Asking for confirmation before partitioning
read -p "Now ${DEV} will be partitioned with a swap size of ${SWAP}GiB. Continue? Type 'go': " ANSWER

if [ "$ANSWER" = "go" ]; then
    echo "Partitioning ${DEV}..."
    (
      echo g # new gpt partition table

      echo n # new partition
      echo 3 # partition 3
      echo   # default start sector
      echo +512M # size is 512M

      echo n # new partition
      echo 1 # first partition
      echo   # default start sector
      echo -${SWAP}G # last N GiB

      echo n # new partition
      echo 2 # second partition
      echo   # default start sector
      echo   # default end sector

      echo t # set type
      echo 1 # first partition
      echo 20 # Linux Filesystem

      echo t # set type
      echo 2 # first partition
      echo 19 # Linux swap

      echo t # set type
      echo 3 # first partition
      echo 1 # EFI System

      echo p # print layout

      echo w # write changes
    ) | sudo fdisk ${DEV}
else
    echo "Cancelled."
    exit
fi

echo "--------------------------------------------------------------------------------"
echo "Checking partition alignment..."

# Function to check partition alignment
function align_check() {
    (
      echo
      echo $1
    ) | sudo parted $DEV align-check | grep aligned | sed "s/^/Partition /"
}

align_check 1
align_check 2
align_check 3

echo "--------------------------------------------------------------------------------"
echo "Getting the names of created partitions..."

# Storing the names of created partitions
declare -a PARTITIONS
i=1
for part in $(sudo fdisk -l | grep $DEV | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    PARTITIONS[$i]=$part
    i=$((i+1))
done

P1=${PARTITIONS[2]}
P2=${PARTITIONS[3]}
P3=${PARTITIONS[4]}

echo "--------------------------------------------------------------------------------"
read -p "Press enter to install NixOS." NULL

echo "Making filesystem on ${P1}..."

# Making filesystem on root partition
sudo mkfs.ext4 -L nixos ${P1}

echo "Enabling swap..."

# Creating and enabling swap
sudo mkswap -L swap ${P2}
sudo swapon ${P2}

echo "Making filesystem on ${P3}..."

# Making filesystem on boot partition (for UEFI systems only)
sudo mkfs.fat -F 32 -n boot ${P3}

echo "Mounting filesystems..."

# Mounting created partitions
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot

echo "Generating NixOS configuration..."

# Generating NixOS configuration
sudo nixos-generate-config --root /mnt

read -p "Press enter to open NixOS configuration. Choose editor (1 for nano, 2 for vi): " EDITOR_CHOICE

case $EDITOR_CHOICE in
    "1")
        sudo nano /mnt/etc/nixos/configuration.nix
        ;;
    "2")
        sudo vi /mnt/etc/nixos/configuration.nix
        ;;
    *)
        echo "Invalid choice. Opening configuration with nano by default."
        sudo nano /mnt/etc/nixos/configuration.nix
        ;;
esac

# Adding additional user after installation
read -p "Do you want to add an additional user? (y/n): " ADD_USER

if [ "$ADD_USER" = "y" ]; then
    read -p "Enter the username: " USERNAME
    sudo chroot /mnt useradd -m -G wheel -s /bin/bash $USERNAME
    sudo chroot /mnt passwd $USERNAME
fi

echo "Installing NixOS..."

# Installing NixOS
sudo nixos-install

read -p "Remove installation media and press enter to reboot." NULL

echo -ne "
------------------------------------------------------------------------------------------------
$$\   $$\                 $$\                     $$\   $$\ $$\            $$$$$$\            
$$ |  $$ |                $$ |                    $$$\  $$ |\__|          $$  __$$\           
$$ |  $$ | $$$$$$\   $$$$$$$ | $$$$$$\   $$$$$$$\ $$$$\ $$ |$$\ $$\   $$\ $$ /  $$ | $$$$$$$\ 
$$$$$$$$ | \____$$\ $$  __$$ |$$  __$$\ $$  _____|$$ $$\$$ |$$ |\$$\ $$  |$$ |  $$ |$$  _____|
$$  __$$ | $$$$$$$ |$$ /  $$ |$$$$$$$$ |\$$$$$$\  $$ \$$$$ |$$ | \$$$$  / $$ |  $$ |\$$$$$$\  
$$ |  $$ |$$  __$$ |$$ |  $$ |$$   ____| \____$$\ $$ |\$$$ |$$ | $$  $$<  $$ |  $$ | \____$$\ 
$$ |  $$ |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ $$$$$$$  |$$ | \$$ |$$ |$$  /\$$\  $$$$$$  |$$$$$$$  |
\__|  \__| \_______| \_______| \_______|\_______/ \__|  \__|\__|\__/  \__| \______/ \_______/
------------------------------------------------------------------------------------------------
                    Pemasang NixOs Otomatis
------------------------------------------------------------------------------------------------
                Done - Please Eject Install Media and Reboot
"

# Rebooting the system after installation is complete
reboot
