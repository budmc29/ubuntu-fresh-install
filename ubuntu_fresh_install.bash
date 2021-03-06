#!/usr/bin/env bash

# Script to install all the required programs and configurations for
# a GNU/Linux enjoyable developing experience
# This of course highly subjective

# TODO: check if dotfiles exists
# TODO: check all the dependencies
# TODO: select what to install?
# TODO: remember to display messages of confirmation
# TODO: install i3wm.bash
# TODO: setup AV chrons (clamscan and chkrootkit)
# TODO: Change order maybe? MySQL requires input

set -o nounset
set -o errexit

user=$(whoami)

main() {
  prepare_repositories
  create_resources
  install_programs
  plugins_setup
  version_control_config
  zsh_setup
  prepare_dotfiles

  echo "---------------------------------------------------------------"
  echo "---------------------------------------------------------------"
  echo "Follow the instructions in Readme to complete the setup"
  echo "---------------------------------------------------------------"
  echo "---------------------------------------------------------------"

  exit 0
}

prepare_repositories() {
  sudo add-apt-repository ppa:nilarimogard/webupd8 # Audio packages
  sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe' # Mysql 5.6

  sudo apt-get update -y  # To get the latest package lists
  sudo apt-get upgrade -y  # To get the latest package list
}

create_resources() {
  DIRS=(
    "/home/$user/.vim/undo"
    "/home/$user/.vim/swap"
    "/home/$user/personal"
    "/home/$user/work"
    "/home/$user/projects"
    "/usr/local/hg-plugins/prompt"
  )

  for dirname in "${DIRS[@]}"; do
    sudo mkdir -p "$dirname"
  done

  touch "/home/$user/.private_work_aliases"

  echo "Directories created"
}

install_rvm() {
  # RVM key to verify the installed version
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

  \curl -sSL https://get.rvm.io | bash -s stable
}

prepare_dotfiles() {
  rm -rf ~/ubuntu-dotfiles

  git clone https://github.com/budmc29/ubuntu-dotfiles ~/ubuntu-dotfiles

  # TODO: Replace this with dotter command
  cp -rT ~/ubuntu-dotfiles/ ~/
  rm -rf ~/.git

  echo "Dotfiles added"
}

install_tmux() {
  VERSION=2.6

  sudo apt-get -y remove tmux
  sudo apt-get -y install libevent-dev libncurses-dev automake pkg-config

  wget https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz

  tar xzf tmux-${VERSION}.tar.gz
  sudo rm -f tmux-${VERSION}.tar.gz
  cd tmux-${VERSION} || exit

  sudo ./configure
  sudo make
  sudo make install
  cd - || exit
  sudo rm -rf /usr/local/src/tmux-*
  sudo mv tmux-${VERSION} /usr/local/src

  /home/$user/.tmux/plugins/tpm/bin/install_plugins
}

install_programs() {
  sudo service apache2 stop

  # Programs by groups listed
  #
  # Personal
  # Work
  # Gems
  # I3 enhancements

  # alsa-utils: i3wm sound card scripts
  # acip: i3wm battery status
  # gufw: firewall manager
  PROGRAMS=(
    "mercurial"
    "pulseaudio-equalizer"
    "xclip"
    "vlc"
    "chromium-browser"
    "filezilla"
    "mysql-client-5.6"
    "mysql-server-5.6"
    "vim-gtk"
    "silversearcher-ag"
    "rxvt-unicode"
    "clamav"
    "clamav-daemon"
    "gufw"
    "kdiff3"
    "exuberant-ctags"
    "sysstat"
    "alsa-utils"
    "acpi"
    "chkrootkit"
    "p7zip-full"
    "gimp"
    "mysql-workbench"
    "curl"
    "gpick"
    "screenruler"

    "nodejs"
    "apache2"
    "nginx"
    "imagemagick"
    "redis-server"

    "libxslt-dev"
    "libxml2-dev"
    "libmysqlclient-dev"
    "libqtwebkit-dev"
    "libqt4-dev"
    "libmysqlclient-dev"
    "libcurl4-gnutls-dev"
    "libmagickwand-dev"

    "i3"
    "arandr"
    "ranger"
    "compton"
    "ruby-ronn"
    "lxappearance"
  )

  for program in "${PROGRAMS[@]}"; do
    sudo apt-get install "$program" -y
  done

  install_tmux
  install_fonts
  install_rvm
  install_elasticsearch
  install_skype
  install_playerctl

  setup_i3
}

zsh_setup() {
  rm -rf /home/$user/.oh-my-zsh

  sudo apt-get install zsh

  curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
  sudo chsh -s "$(which zsh)"

  echo "Oh My Zsh installed"
}

setup_i3() {
  mkdir -p i3_setup
  cd i3_setup || exit

  wget https://github.com/acrisci/playerctl/releases/download/v0.4.2/playerctl-0.4.2_amd64.deb

  sudo dpkg -i playerctl*

  # Rofi app launcher
  wget https://launchpad.net/ubuntu/+source/rofi/0.15.11-1/+build/8289001/+files/rofi_0.15.11-1_amd64.deb
  sudo dpkg -i rofi*.deb

  # i3blocks
  git clone git://github.com/vivien/i3blocks
  cd i3blocks || exit

  sudo make clean all
  sudo make install

  cd ../../ || exit

  rm i3_setup/ -rf

  echo "I3 installed successfully"
}

version_control_config() {
  git config --global user.email "chirica.mugurel@gmail.com"
  git config --global user.name "Mugur (Bud) Chirica"

  sudo cp prompt.py /usr/local/hg-plugins/prompt

  sudo chmod 777 -R /usr/local/hg-plugins
}

plugins_setup() {
  # Vundle plugin manager for vim
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

  # Tmux plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  chmod -R 777 ~/.tmux

  # Vim plugins
  vim +PluginInstall +qall
}

install_fonts() {
  version=1.010

  rm -f SourceCodePro_FontsOnly-$version.zip
  rm -rf SourceCodePro_FontsOnly-$version

  wget https://github.com/downloads/adobe/source-code-pro/SourceCodePro_FontsOnly-$version.zip

  unzip SourceCodePro_FontsOnly-$version.zip
  mkdir -p ~/.fonts

  cp SourceCodePro_FontsOnly-$version/OTF/*.otf ~/.fonts/

  rm -rf SourceCodePro_FontsOnly*

  # Install San Francisco font system wide
  wget https://github.com/supermarin/YosemiteSanFranciscoFont/archive/master.zip
  unzip master.zip
  rm master.zip*

  # Move to system fonts
  mv Yo*/*.ttf ~/.fonts
  rm Yo* -rf


  # Update fonts cache
  sudo fc-cache -f -v

  echo "Fonts installed"
}

install_elasticsearch() {
  wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.2.1.deb
  sudo dpkg -i elasticsearch-1.2.1.deb
  sudo update-rc.d elasticsearch defaults 95 10
  sudo /etc/init.d/elasticsearch start

  rm elastic*

  echo "Elasticsearch installed"
}

install_skype() {
  wget https://repo.skype.com/latest/skypeforlinux-64.deb
  sudo dpkg -i skypeforlinux-64.deb

  rm skype*

  echo "Skype installed"
}

install_playerctl() {
  version=0.5.0
  file=playerctl-${version}_amd64.deb

  wget https://github.com/acrisci/playerctl/releases/download/v${version}/$file
  sudo dpkg -i $file

  rm $file

  echo "Playerctl installed"
}

main "$@"
