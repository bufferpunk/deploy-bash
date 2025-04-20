#!/usr/bin/env bash
## ./package_install.sh
## Installs all the packages required for the Libly project

# Bold colors
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
Color_Off='\033[0;37m'    # White

# Non-bold colors
Black='\033[0;30m'       # Black
Red='\033[0;31m'         # Red
Green='\033[0;32m'       # Green
Yellow='\033[0;33m'      # Yellow
Blue='\033[0;34m'        # Blue
Purple='\033[0;35m'      # Purple
Cyan='\033[0;36m'        # Cyan
White='\033[0'           # White

set -e

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

user_can_sudo() {
  # Check if sudo is installed
  command_exists sudo || return 1
  # Termux can't run sudo, so we can detect it and exit the function early.
  case "$PREFIX" in
  *com.termux*) return 1 ;;
  esac
  # The following command has 3 parts:
  #
  # 1. Run `sudo` with `-v`. Does the following:
  #    • with privilege: asks for a password immediately.
  #    • without privilege: exits with error code 1 and prints the message:
  #      Sorry, user <username> may not run sudo on <hostname>
  #
  # 2. Pass `-n` to `sudo` to tell it to not ask for a password. If the
  #    password is not required, the command will finish with exit code 0.
  #    If one is required, sudo will exit with error code 1 and print the
  #    message:
  #    sudo: a password is required
  #
  # 3. Check for the words "may not run sudo" in the output to really tell
  #    whether the user has privileges or not. For that we have to make sure
  #    to run `sudo` in the default locale (with `LANG=`) so that the message
  #    stays consistent regardless of the user's locale.
  #
  ! LANG= sudo -n -v 2>&1 | grep -q "may not run sudo"
}

if ! user_can_sudo; then
  echo -e "${BRed}Error: You need to have sudo privileges to run this script, else it won't work.${Color_Off}"
  exit 1
fi

if [ ! -d "$HOME/.Libly" ]; then
  echo "Error: ~/.Libly not found. Please deploy the project correctly by running the deploy.sh script."
  exit 1
fi

cd ~/.Libly
WD=$(pwd)

echo -e "${Yellow}Working directory: $WD${Color_Off}"

if ! which "zsh" &> /dev/null; then
    answer="y"
    if ! [[ "$*" =~ (^|[[:space:]])--force($|[[:space:]]) ]]; then
        printf "${Purple}Zsh is not installed. It is our favorite shell, and our deployment depends on it. Do you want to install it? (y/n) ${Color_Off}"
        read -p " " answer
    fi
    answer=${answer,,} # Convert to lowercase
    if [[ $answer == "y" ]]; then
        sudo apt-get install zsh git -y
        # change the default shell to zsh
        sudo -k chsh -s "$zsh" "$USER"
    else
        echo "zsh is required to run this script. Exiting..."
        exit 1
    fi
fi

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BBlue}Installing oh-my-zsh...${Color_Off} (Please rerun the script after installation)"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

sudo apt-get install nano nginx gunicorn python3 python3-pip certbot python3-certbot-nginx dnsutils bind9-host -y
curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install nodejs mysql-client mysql-server pkg-config python3-dev default-libmysqlclient-dev build-essential python3-venv -y

## The venv should be outside of current version, to prevent having to reinstall dependencies on every release
python3 -m venv venv
source venv/bin/activate
pip3 install --quiet --upgrade pip
pip3 install -r "$WD/current/deployment/requirements.txt"
cd current/node_api
npm install
cd ..

printf "${BGreen}All packages installed successfully.\n${Color_Off}"
printf "${Yellow}Please run the server_setup.sh script to set up the server. \n\n${Color_Off}"
