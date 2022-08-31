#!/bin/bash
# To add this repository please do:
echo "### BEGIN POST INSTALL ###"

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

buildDir=$(pwd)

# Update packages list
${SUDO} apt update
${SUDO} apt upgrade -y

# Install gnome desktop
${SUDO} apt -y install gnome-session gnome-terminal firefox-esr gnome-tweaks gnome-disk-utility gnome-font-viewer \
gnome-shell-extensions-prefs gnome-calculator gnome-characters gnome-control-center gnome-color-manager gnome-keyring \
gnome-logs gnome-menus gnome-system-monitor gnome-text-editor

${SUDO} apt -y install apt-transport-https lsb-release ca-certificates curl ufw vlc timeshift nvidia-detect \
zsh neofetch htop build-essential dkms linux-headers-$(uname -r) gnupg

# Install Nvidia driver
${SUDO} nvidia-detect
${SUDO} apt -y install nvidia-driver

# Qemu
egrep -c '(vmx|svm)' /proc/cpuinfo
${SUDO} apt -y install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager
${SUDO} systemctl status libvirtd.service
${SUDO} virsh net-start default
${SUDO} virsh net-autostart default
${SUDO} virsh net-list --all
${SUDO} adduser $USER libvirt
${SUDO} adduser $USER libvirt-qemu

# Install Packages
echo "### INSTALLING PACKAGES ###"
${SUDO} dpkg -i "$buildDir/packages/ulauncher_5.14.7_all.deb"
${SUDO} apt install -f

# Docker
${SUDO} apt remove docker docker-engine docker.io containerd runc
${SUDO} mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
${SUDO} apt update
${SUDO} apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
${SUDO} groupadd docker
${SUDO} usermod -aG docker $USER

# Php
${SUDO} curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
${SUDO} sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
${SUDO} apt update
${SUDO} apt -y install php8.1 php8.1-{bcmath,fpm,xml,mysql,zip,intl,ldap,gd,cli,bz2,curl,mbstring,pgsql,opcache,soap,cgi}
echo "### INSTALLING PACKAGES DONE ###"

# Setup Appearance
echo "### SETTING UP APPEARANCE ###"
cd $buildDir
# ${SUDO} mkdir -p /boot/grub/themes/acer
# ${SUDO} tar xvf themes/acer.tar -C /boot/grub/themes/acer
${SUDO} apt -y install imagemagick
git clone https://github.com/vinceliuice/grub2-themes.git
cp -r images/bg.png grub2-themes/background.jpg
cd grub2-themes
${SUDO} ./install.sh -b -t whitesur -s 1080p
${SUDO} grub-mkconfig -o /boot/grub/grub.cfg
cd ..
${SUDO} install -y plymouth plymouth-themes
${SUDO} tar xvf themes/debian-logo.tar.xz -C /usr/share/plymouth/themes/
${SUDO} plymouth-set-default-theme -R debian-logo
${SUDO} cp -r /etc/default/grub /etc/default/grub.old
${SUDO} cp -r config/grub /etc/default/grub
${SUDO} update-grub

# Layan Cursors
mkdir -p $HOME/build
cd "$HOME/build"
git clone https://github.com/vinceliuice/Layan-cursors
cd Layan-cursors
${SUDO} ./install.sh

# Download Nordic Theme
cd /usr/share/themes/
${SUDO} git clone https://github.com/EliverLara/Nordic.git
gsettings set org.gnome.desktop.interface gtk-theme "Nordic"
gsettings set org.gnome.desktop.wm.preferences theme "Nordic"
echo "### SETTING UP APPEARANCE DONE ###"

# Customize zsh
echo "### CUSTOMIZING ZSH ###"
cd $buildDir
${SUDO} cp -r fonts /usr/share/fonts
fc-cache -vf
${SUDO} chsh -s $(which zsh)
# ${SUDO} apt install zsh-syntax-highlighting zsh-autosuggestions
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cp -r "$buildDir/config/.zshrc" $HOME
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
touch "$HOME/.zsh_history"
touch "$HOME/.histfile"
cp -r "$buildDir/config/.p10k.zsh" $HOME
echo "### CUSTOMIZING ZSH DONE ###"

echo "### POST INSTALLATION DONE ###"
