#! /bin/bash

# DISCLAIMER: This script is currently under development and hasn't been tested !!!

#-------------------------------------------------------------------------------------------------------
#
# Filename : installation.sh
# Description: Script for auto installing and configuring software in several linux distros
# Author: Alexandros Dorodoulis
#
# Software for distros with "apt-get":
#   Software for Ubuntu :
#     Tools: Wget, Curl, Git, Dropbox, Ubuntu Make, Ubuntu restricted, Unity tweak
#     Text Editors: Vim,  Atom, Sublime
#     Multimedia Vlc, Gimp, Spotify
#     Browsers: Firefox for developers, Chromium, Chrome
#     Mail Clients / IM: Thunderbird
#     Security: Iptables, Wireshark, Hydra, Nmap, Aircrack-ng, Medusa
#     Compilers: Python, Oracle's jdk 8, Ruby, G++, GCC
#     IDEs: IntelliJ IDEA, Android Studio, Eclipse, Pycharm
#   Other distros: Wget vim git curl zsh tmux g++ gcc nmap iptables python Sublime-Text 3 Atom TO DO
# Software for distros with "yum" : Wget vim git curl zsh tmux g++ gcc nmap iptables python Sublime-Text 3 Atom TO DO
# Software for distros with "zypper" : Wget vim git curl zsh tmux g++ gcc nmap iptables python Sublime-Text 3 Atom TO DO
# Software for distros with "pacman" : Wget vim git curl zsh tmux g++ gcc nmap iptables python TO DO
#
#-------------------------------------------------------------------------------------------------------

export distro=$(lsb_release -si) # Linux distribution
export displayLog=false
export logDir="/var/log/installation_script" # Log directory
export logFile="$logDir/installation_script.log" # Log file
export architecture=$(uname -m) # Computer's architecture
export tempDir=$(mktemp -d /tmp/tempdir.XXXXXXXX) # Create temp directory
export alreadyInstalledCode=999
userRunningTheScript=$SUDO_USER

# Set home path
if [[ ! -z  $userRunningTheScript ]]; then
	userHome="/home/$userRunningTheScript/"
else
	userHome="/root/"
fi

# Programms to be installed from the official reposittories
declare -a tools=(wget vim git curl zsh tmux g++ gcc python)
declare -a security=(nmap iptables)

# Check for root privilages
function check_root_privilages(){
   if [[ $EUID -ne 0 ]]; then
     echo "This script needs root privilages"
     exit 1
   fi
}

# Check the internet connection
function check_conection(){
  if [ ! "$(ping -c 1 google.com)" ];then
    echo "Please check your internet connection and execute the script again"
    exit 2
  fi
}

# Find the package manager
function find_package_manager_tool(){
  if [ -x "$(which apt-get)" ];  then
    packageManagerTool="apt-get"
  elif [ -x "$(which yum)" ]; then
    packageManagerTool="yum"
  elif [ -x "$(which zypper )" ]; then
    packageManagerTool="zypper"
  elif [ -x "$(which pacman)" ]; then
    packageManagerTool="pacman"
  else
      echo "Your package manager isn't supported"
      exit 3
  fi
}

# Create log directory
function create_log_directory(){
    	if [ ! -d $logDir ];then
    		mkdir $logDir
    		chown $USER:$USER $logDir
    	fi
    	if [ -e $logFile ];then
    		mv $logFile $logFile$(date +%Y%m%d).log
    		touch $logFile
    	fi
}

# Write log file
function write_log(){
  if [ -z "$2" ];then
    echo "$1 : Parameter error" >> $logFile
  else
    case $2 in
      0)
        echo "$1 : successfully installed" >> $logFile
        ;;
      $alreadyInstalledCode)
        echo "$1 : already installed" >> $logFile
        ;;
      *)
        echo "$1 : installation failed (error code = $2)" >> $logFile
        showLog=true
        ;;
      esac
    fi
}

# Install applications from reposittories
function install_repo_apps(){
  name=$1[@]
  arrayName=("${!name}")
  for i in "${arrayName[@]}"; do
    if ! appLocation="$(type -p "$i")" || [ -z "$appLocation" ]; then # Check if the application isn't installed
      case $packageManagerTool in
    	pacman)
    		$packageManagerTool -S --noconfirm --needed $i
    	;;
    	*)
    		$packageManagerTool install -y $i
    	;;
    	esac
	  exitLog=$?
    write_log $i $exitLog
    else
      write_log $i $alreadyInstalledCode
    fi
  done
}

# Configure tmux
function configure_tmux(){
  # Check for existing files or directories and create needed ones
    if [[ -e $userHome.tmux.conf ]] ; then
  	   mv $userHome.tmux.conf $userHome.tmux.conf.old$(date +%Y%m%d)
  	  fi
    if [[ ! -d $userHome.tmux ]] ; then
	     mkdir $userHome.tmux
    else
      if [[ -e $userHome.tmux/inx ]] ; then
    	   mv $userHome.tmux/inx $userHome.tmux/inx.old$(date +%Y%m%d)
    	  fi
      if [[ -e $userHome.tmux/xless ]] ;
	       then mv $userHome.tmux/xless $userHome.tmux/xless.old$(date +%Y%m%d)
	      fi
    fi
  # Download configuration files
    wget -O $userHome.tmux.conf -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux.conf
    wget -O $userHome.tmux/inx -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux/inx
    wget -O $userHome.tmux/xless -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux/xless
}

# Install and configure oh-my-zsh
function configure_zsh(){
  wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -q -O - | bash

  # Install zsh-syntax-highlighting
    if [[ ! -d $userHome.oh-my-zsh/custom ]]; then
	     mkdir $userHome.oh-my-zsh/costum
	    fi
    cd $userHome.oh-my-zsh/custom/plugins
    git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
    cd $tempDir

  # Configure .zshrc
    sed -i 's/#COMPLETION_WAITING_DOTS/COMPLETION_WAITING_DOTS/' $userHome.zshrc
    sed -i 's/robbyrussell/wedisagree/' $userHome.zshrc
    sed -i 's/plugins=(.*/plugins=(git command-not-found tmux zsh-syntax-highlighting)/g' $userHome.zshrc

  # Set zsh as the default shell
    chsh -s $(which zsh) $userRunningTheScript
}

# Install the latest build of Sublime Text 3
function install_sublime_text_3(){
  aptGetUrl="http://c758482.r82.cf2.rackcdn.com/sublime-text_build-"
  elseGetUrl="http://c758482.r82.cf2.rackcdn.com/sublime_text_3_build_"
  build=$(curl -Ls https://www.sublimetext.com/3 |
          grep '<h2>Build' | head -n1 |
          sed -E 's#<h2>Build ([0-9]+)</h2>#\1#g')
  sublimeName="Sublime_Text_3_$build"

  if [ "$packageManagerTool" = "apt-get" ]; then
    if [[ ! -z $(which subl) && $(subl -v | awk '{print $NF}') == $build ]] ; then
      write_log $sublimeName $alreadyInstalledCode
    else
      if [ $architecture == "x86_64" ]; then
        url=$aptGetUrl$build"_amd64.deb"
      else
        url=$aptGetUrl$build"_i386.deb"
      fi
      wget -q $url
      dpkg -i sublime-text_build*
      exitLog=$?
      write_log $sublimeName $exitLog
    fi
  else
    if [[ ! -z $(which subl) && $(subl -v | awk '{print $NF}') == $build ]] ; then
      write_log $sublimeName $alreadyInstalledCode
    else
      if [ $architecture == "x86_64" ]; then
        url=$elseGetUrl$build"_x64.tar.bz2"
      else
        url=$elseGetUrl$build"_x32.tar.bz2"
      fi
      wget -q $url
      tar vxjf sublime*
      rm sublime*.tar.br2
      cp sublime_text_3 /opt/
      ln -s /opt/sublime_text_3/sublime_text /usr/bin/subl
    fi
  fi
}

#Installing Atom-Editor
function install_atom_editor(){
  case $packageManagerTool in
    apt-get)
      #TO DO
      # Install atom
      if ! appLocation="$(type -p "atom")" || [ -z "$appLocation" ]; then
        wget -O atom.deb -q https://atom.io/download/deb
        dpkg -i atom.deb
        exitLog=$?
      else
          write_log atom $alreadyInstalledCode
      fi
      ;;
    yum | zypper)
      #TO DO
      # Install atom
      if ! appLocation="$(type -p "wget")" || [ -z "$appLocation" ]; then
        wget -O atom.rpm -q https://atom.io/download/rpm
        rpm -i atom.rpm
      else
          write_log atom $alreadyInstalledCode
      fi
      ;;
    pacman)
      #TO DO
      ;;
  esac
}
# Main part
check_conection
check_root_privilages
find_package_manager_tool
create_log_directory

cd $tempDir

if [[ $distro = "Ubuntu" ]];then
  if ! appLocation="$(type -p "wget")" || [ -z "$appLocation" ]; then
    apt-get install -y wget
    exitLog=$?
    write_log wget $exitLog
  else
      write_log wget $alreadyInstalledCode
  fi
  https://raw.githubusercontent.com/alexdor/linuxscripts/master/installation_ubuntu.sh | bash
else
  install_repo_apps tools
  install_repo_apps security
  install_sublime_text_3
  install_atom_editor
  configure_tmux
  configure_zsh
fi

rm -rf $tempDir
