#!/bin/sh
#
# Skrip untuk menginstal NixOS setelah booting dari gambar USB minimal.
#
# Untuk menjalankan:
#
#     sh -c "$(curl https://url.dwirz.my.id/nixos.sh)"
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
                    Pemasang NixOs Otomatis
------------------------------------------------------------------------------------------------
                Skrip ada di direktori bernama HadesNixOs
"

echo "--------------------------------------------------------------------------------"
echo "Berikut adalah daftar perangkat penyimpanan yang terpasang."
read -p "Tekan 'q' untuk keluar dari daftar. Tekan enter untuk melanjutkan." NULL

# Menampilkan daftar perangkat penyimpanan yang terpasang
sudo fdisk -l | less

echo "--------------------------------------------------------------------------------"
echo "Perangkat yang Terdeteksi:"
echo

# Menyimpan daftar perangkat penyimpanan yang terdeteksi
declare -a DEVICES
i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
    echo "[$i] $device"
    DEVICES[$i]=$device
    i=$((i+1))
done

echo
read -p "Pada perangkat mana Anda ingin menginstal? Masukkan nomor perangkat: " DEVICE

# Memilih perangkat untuk instalasi
DEV=${DEVICES[$DEVICE]}

# Meminta pengguna untuk memasukkan ukuran ruang swap yang diinginkan
read -p "Berapa besar ruang swap yang Anda perlukan dalam GiB (contoh: 8)? " SWAP

# Meminta konfirmasi sebelum mempartisi
read -p "Sekarang ${DEV} akan dipartisi dengan ukuran swap ${SWAP}GiB. Lanjutkan? Ketik 'go': " ANSWER

if [ "$ANSWER" = "go" ]; then
    echo "Mempartisi ${DEV}..."
    (
      echo g # tabel partisi gpt baru

      echo n # partisi baru
      echo 3 # partisi 3
      echo   # sektor awal default
      echo +512M # ukuran adalah 512M

      echo n # partisi baru
      echo 1 # partisi pertama
      echo   # sektor awal default
      echo -${SWAP}G # terakhir N GiB

      echo n # partisi baru
      echo 2 # partisi kedua
      echo   # sektor awal default
      echo   # sektor akhir default

      echo t # atur jenis
      echo 1 # partisi pertama
      echo 20 # Sistem File Linux

      echo t # atur jenis
      echo 2 # partisi pertama
      echo 19 # swap Linux

      echo t # atur jenis
      echo 3 # partisi pertama
      echo 1 # Sistem EFI

      echo p # cetak tata letak

      echo w # tulis perubahan
    ) | sudo fdisk ${DEV}
else
    echo "Dibatalkan."
    exit
fi

echo "--------------------------------------------------------------------------------"
echo "Memeriksa penyelarasan partisi..."

# Fungsi untuk memeriksa penyelarasan partisi
function align_check() {
    (
      echo
      echo $1
    ) | sudo parted $DEV align-check | grep aligned | sed "s/^/Partisi /"
}

align_check 1
align_check 2
align_check 3

echo "--------------------------------------------------------------------------------"
echo "Mendapatkan nama partisi yang dibuat..."

# Menyimpan nama partisi yang dibuat
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
read -p "Tekan enter untuk menginstal NixOS." NULL

echo "Membuat sistem file pada ${P1}..."

# Membuat sistem file pada partisi root
sudo mkfs.ext4 -L nixos ${P1}

echo "Mengaktifkan swap..."

# Membuat dan mengaktifkan swap
sudo mkswap -L swap ${P2}
sudo swapon ${P2}

echo "Membuat sistem file pada ${P3}..."

# Membuat sistem file pada partisi boot (hanya untuk sistem UEFI)
sudo mkfs.fat -F 32 -n boot ${P3}

echo "Mounting filesystems..."

# Melakukan mounting partisi yang telah dibuat
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot

echo "Menghasilkan konfigurasi NixOS..."

# Menghasilkan konfigurasi NixOS
sudo nixos-generate-config --root /mnt

read -p "Tekan enter untuk membuka konfigurasi NixOS. Pilih editor (1 untuk nano, 2 untuk vi): " EDITOR_CHOICE

case $EDITOR_CHOICE in
    "1")
        sudo nano /mnt/etc/nixos/configuration.nix
        ;;
    "2")
        sudo vi /mnt/etc/nixos/configuration.nix
        ;;
    *)
        echo "Pilihan tidak valid. Membuka konfigurasi dengan nano secara default."
        sudo nano /mnt/etc/nixos/configuration.nix
        ;;
esac

# Menambahkan pengguna tambahan setelah instalasi
read -p "Apakah Anda ingin menambahkan pengguna tambahan? (y/t): " ADD_USER

if [ "$ADD_USER" = "y" ]; then
    read -p "Masukkan nama pengguna: " USERNAME
    sudo chroot /mnt useradd -m -G wheel -s /bin/bash $USERNAME
    sudo chroot /mnt passwd $USERNAME
fi

echo "Menginstal NixOS..."

# Menginstal NixOS
sudo nixos-install

read -p "Hapus media instalasi dan tekan enter untuk me-reboot." NULL

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
                Selesai - Harap Keluarkan Media Instalasi dan Reboot
"

# Me-reboot sistem setelah instalasi selesai
reboot
