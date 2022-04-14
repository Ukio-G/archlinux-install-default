#!/usr/bin/bash

#	Simple disk configuration

efi_filesystem="EF00"

pacstrap_packages="base linux linux-firmware"

regexp_full_device_line='/dev/sd[abcd].*GiB|/dev/nvme[0-9a-z]*.*GiB' 
regexp_device_name_only='/dev/sd[abcd]|/dev/nvme[0-9a-z]*'
regexp_device_space='[0-9]'

if [[ $device_install_to == "" ]]; then
	device_install_to=`fdisk --list | grep -E -o "$regexp_full_device_line" | grep -E -o "$regexp_device_name_only"`
fi

echo "Creating table for $device_install_to"

sfdisk -o $device_install_to > /dev/null

echo "label: gpt" | sfdisk $device_install_to

sleep 2

free_disk_space=`parted $device_install_to print | grep $device_install_to | gawk 'match($0,/: ([0-9]*).*/,a){print a[1]}'`

root_size=`echo "$free_disk_space - 1" | bc`

parted $device_install_to -s mkpart ESP fat32 1M 512MiB
parted $device_install_to -s mkpart primary ext4 512MiB $root_size"GB"
parted $device_install_to -s mkpart primary linux-swap $root_size"GB" 100%
parted $device_install_to -s set 1 boot on

mkfs.vfat -F32 $device_install_to"1"
mkfs.ext4 -F $device_install_to"2"
mkswap $device_install_to"3"

mount $device_install_to"2" /mnt
mkdir -p /mnt/boot/efi
mount $device_install_to"1" /mnt/boot/efi

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

ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

pacman -Sy
pacman -S --noconfirm --needed --noprogressbar --quiet reflector
reflector -l 3 --sort rate --save /etc/pacman.d/mirrorlist

pacman -Syu
pacman -S  --noconfirm --needed archlinux-keyring sudo base-devel

# pacman -S  --noconfirm --needed zsh \
# 								git \
# 								gcc \
# 								make \
# 								vim \
# 								iwd \
# 								dhcpcd \
# 								wget \
# 								wpa_supplicant \
# 								reflector \
# 								sudo \
# 								thunar \
# 								i3-wm \
# 								rofi \
# 								xterm \
# 								unzip \
# 								openssh \
# 								openvpn \
# 								xorg-server \
# 								thunar-archive-plugin \
# 								thunar-volman \
# 								rxvt-unicode \
# 								htop \
# 								netctl \
# 								zip \
# 								ttf-hack \
# 								i3blocks \
# 								xorg-xrdb \
# 								xbindkeys \
# 								zsh-syntax-highlighting \
# 								zsh-autosuggestions \
# 								xmlto \
# 								kmod \
# 								inetutils \
# 								bc \
# 								libelf \
# 								feh \
# 								xorg-xinit \
# 								guake \
# 								lxrandr \
# 								ttf-font-awesome \
# 								telegram-desktop \
# 								audacious \
# 								audacious-plugins \
# 								alsa-lib \
# 								alsa-utils \
# 								chromium 


useradd -m -g users -G audio,wheel -s \`which zsh\` ukio
sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers

echo ukio_host > /etc/hostname

echo ukio:123 | chpasswd
echo root:456 | chpasswd

pacman -S --noconfirm --needed grub intel-ucode efibootmgr


root_uuid=\`cat /etc/fstab | grep -E 'UUID=.*/ ' | gawk 'match(\$0,/UUID=(.*)\s*\/ /,a) {print a[1]}'\`


sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen

chmod 777 /user_setup.sh


cd /root
#git clone https://github.com/vivien/i3blocks-contrib
#cd i3blocks-contrib
#chmod -R +x .

#mkdir /usr/lib/i3blocks
#cp -r * /usr/lib/i3blocks

#cd .. && rm -rf i3blocks-contrib


#/bin/su -s /bin/bash -c '/user_setup.sh' ukio

sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers


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

git clone https://github.com/denysdovhan/spaceship-prompt.git "\$ZSH_CUSTOM/themes/spaceship-prompt"

ln -s "\$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "\$ZSH_CUSTOM/themes/spaceship.zsh-theme"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

rm install.sh

EOF


arch-chroot /mnt /bin/bash -e -x /second.sh
# rm /mnt/second.sh



#### End of post-configuration and reboot