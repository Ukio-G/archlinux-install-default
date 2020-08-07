# archlinux-install-default

Script that automates routine installation steps.

## Main set of installed packages

- wm: i3wm + i3blocks + i3blocks-contrib (https://github.com/vivien/i3blocks-contrib) + rofi
- terminal emulator: rxvt-unicode + guake
- shell: zsh + fsf + zsh-syntax-highlighting + zsh-autocomplete
- file manager: thunar
- browser: chromium
- audio player: audacious
- fonts: iosevka (https://aur.archlinux.org/packages/ttf-iosevka/), ttf-hack, ttf-font-awesome
- network managers and utilites: netctl + iwd + wpa_supplicant + openssh + openvpn
- develop: vim + gcc + make + git

## Requirements and limitations

- Only one disk device using
- To change username you should change ```create_filesystem.sh```
- Dick device name should be ```/dev/sd[a-z]``` or ```/dev/nvme[0-9]```

## Сonfiguration out of the box

See https://github.com/Ukio-G/dotfile

## ToDo:

- Ability to select a disk device that will be used to install the system
- Select disk install to
- Fix urxvt keys (Ctrl/Alt + arrows) for zsh
- Ability to specify username (not only ukio)
- Fix font in terminal (Prompt ~ display as a)
- Compilation kernel after installation, based on devices set. 
