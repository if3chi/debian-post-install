#!/bin/bash
#################################
#   :::::: C O L O R S ::::::   #
#################################

CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # waring color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"                                # bold warning color

#######################################
#   :::::: F U N C T I O N S ::::::   #
#######################################

# echo like ... with flag type and display message colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;    # print success message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;    # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;    # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;    # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

prompt -i "### BEGIN POST INSTALL ###"

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
gnome-logs gnome-menus gnome-system-monitor gnome-text-editor seahorse avahi-daemon file-roller gstreamer1.0-libav  libgsf-bin \
 libreoffice-writer network-manager-gnome transmission-gtk

${SUDO} apt -y install apt-transport-https lsb-release ca-certificates curl ufw vlc timeshift nvidia-detect \
zsh neofetch htop build-essential dkms linux-headers-$(uname -r) gnupg wget

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
prompt -i "### INSTALLING PACKAGES ###"
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

# GO
wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
${SUDO} rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz
# export PATH=$PATH:/usr/local/go/bin

# Php
#${SUDO} curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
#${SUDO} sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
#${SUDO} apt update
#${SUDO} apt -y install php8.1 php8.1-{bcmath,fpm,xml,mysql,zip,intl,ldap,gd,cli,bz2,curl,mbstring,pgsql,opcache,soap,cgi}
#prompt -s "### INSTALLING PACKAGES DONE ###"

# Setup Appearance
prompt -i "### SETTING UP APPEARANCE ###"
cd $buildDir
# ${SUDO} mkdir -p /boot/grub/themes/acer
# ${SUDO} tar xvf themes/acer.tar -C /boot/grub/themes/acer
${SUDO} apt -y install imagemagick plymouth plymouth-themes
${SUDO} cp -r /etc/default/grub /etc/default/grub.old
${SUDO} cp -r config/grub /etc/default/grub
git clone https://github.com/vinceliuice/grub2-themes.git
cp -r images/bg.png grub2-themes/background.jpg
cd grub2-themes
${SUDO} ./install.sh -b -t whitesur -s 1080p
${SUDO} grub-mkconfig -o /boot/grub/grub.cfg
cd ..
${SUDO} tar xvf themes/debian-logo.tar.xz -C /usr/share/plymouth/themes/
${SUDO} plymouth-set-default-theme -R debian-logo
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
prompt -s "### SETTING UP APPEARANCE DONE ###"

# Customize zsh
prompt -i "### CUSTOMIZING ZSH ###"
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
prompt -i "### CUSTOMIZING ZSH DONE ###"

prompt -s "### POST INSTALLATION DONE ###"
