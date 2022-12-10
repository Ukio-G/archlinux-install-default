#!/usr/bin/bash

efi_filesystem="EF00"

pacstrap_packages="base linux linux-firmware"

device_install_to="nvme0n1"
boot_part="nvme0n1p5"
root_part="nvme0n1p6"
create_gpt_table=0


#TODO: Add manual confirmation for each disk operaton
function prepare_filesystem() {
    if [[ $create_gpt_table -eq 1 ]]; then
        echo "Creating table for $device_install_to"
        sfdisk -o $device_install_to > /dev/null
        echo "label: gpt" | sfdisk $device_install_to
        sleep 2
    fi

	echo "Prepare filesystem on $device_install_to"
	last_sector=parted $device_install_to -s 'unit s print' | tail -2 | grep -E -o '[0-9]*s' | sed -n 2,2p | grep -E -o '[0-9]*'
	echo "Last avalible sector: $last_sector"

	# Boot
	boot_start_sector=`echo "$last_sector + 1" | bc`
	boot_end_sector=`echo "$boot_start_sector + (2048 * 512) - 1" | bc`
	echo "Boot start sector: $boot_start_sector; end sector: $boot_end_sector"
	parted $boot_part -s mkpart ESP fat32 $boot_start_sector $boot_end_sector
	#parted $device_install_to -s set 1 boot on
	
	# Root
	root_start_sector=`echo "$boot_end_sector + 1" | bc`
	# TODO: make root size depends on argument script
	# root_end_sector=`echo "$root_start_sector + (2048 * 512) - 1" | bc`
	echo "Root start sector: $root_start_sector; end sector: $root_end_sector"
	parted $root_part -s mkpart primary ext4 $root_start_sector 100%
	
	# Format new partitions
	mkfs.vfat -F32 $boot_part
	mkfs.ext4 -F $root_part
}


function mount_filesystem() {
	mount $root_part /mnt
	mkdir /mnt/boot
	mount $boot_part /mnt/boot 
}


pacman -Sy
pacman -S --noconfirm --needed --noprogressbar --quiet reflector
reflector -l 3 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt $pacstrap_packages

genfstab -U -p /mnt >> /mnt/etc/fstab

#### Post install actions

cat <<- EOF > /mnt/second.sh

sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen

locale-gen

ln -svf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
hwclock --systohc --utc
pacman-key --init
pacman-key --populate

pacman -Sy
pacman -S --noconfirm --needed --noprogressbar --quiet reflector
reflector -l 3 --sort rate --save /etc/pacman.d/mirrorlist

pacman -Syu
pacman -S  --noconfirm --needed archlinux-keyring sudo base-devel
pacman -S  --noconfirm --needed zsh \
								git \
								gcc \
								make \
								vim \
								iwd \
								dhcpcd \
								wget \
								wpa_supplicant \
								reflector \
								sudo \
								thunar \
								i3-wm \
								rofi \
								xterm \
								unzip \
								openssh \
								openvpn \
								xorg-server \
								thunar-archive-plugin \
								thunar-volman \
								rxvt-unicode \
								htop \
								netctl \
								zip \
								ttf-hack \
								i3blocks \
								xorg-xrdb \
								xbindkeys \
								zsh-syntax-highlighting \
								zsh-autosuggestions \
								xmlto \
								kmod \
								inetutils \
								bc \
								libelf \
								feh \
								xorg-xinit \
								guake \
								lxrandr \
								ttf-font-awesome \
								telegram-desktop \
								audacious \
								audacious-plugins \
								alsa-lib \
								alsa-utils \
								chromium 


useradd -m -g users -G audio,wheel -s \`which zsh\` ukio
sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers

echo ukio_host > /etc/hostname

echo ukio:1 | chpasswd
echo root:2 | chpasswd

pacman -S --noconfirm --needed grub efibootmgr
pacman -S --noconfirm --needed intel-ucode


sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen

chmod 777 /user_setup.sh

cd /root
git clone https://github.com/vivien/i3blocks-contrib
cd i3blocks-contrib
chmod -R +x .

mkdir /usr/lib/i3blocks
cp -r * /usr/lib/i3blocks

cd .. && rm -rf i3blocks-contrib


/bin/su -s /bin/bash -c '/user_setup.sh' ukio

sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux
grub-mkconfig -o /boot/grub/grub.cfg
EOF




cat <<- EOF > /mnt/user_setup.sh


# install fonts

cd ~
mkdir aur-stuff && cd aur-stuff

git clone https://aur.archlinux.org/ttf-iosevka.git
cd ttf-iosevka
makepkg -sri --noconfirm

git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

source ~/.zshrc

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

cd ~
git clone https://github.com/Ukio-G/dotfile.git
cd dotfile
sh ./install.sh

sleep 1

# git clone https://github.com/denysdovhan/spaceship-prompt.git "\$ZSH_CUSTOM/themes/spaceship-prompt"

# ln -s "\$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "\$ZSH_CUSTOM/themes/spaceship.zsh-theme"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions


rm install.sh

EOF

arch-chroot /mnt /bin/bash -e -x /second.sh
rm /mnt/second.sh

echo "Umounting /mnt..."
umount -R /mnt

#### End of post-configuration and reboot
