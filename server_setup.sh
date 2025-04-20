#!/usr/bin/env bash
## Copyright (c) 2025 Buffer Park and contributors
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
## You should have received a copy of the GNU General Public License
## along with this program. If not, see <http://www.gnu.org/licenses/>.

## This script deploys the Libly project on a server. (Hands off deployment)
## It sets up the server with the necessary configurations.

# Bold colors
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
Color_Off='\033[0;37m'    # White

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

## Check if zsh is installed
if ! command -v zsh &> /dev/null
then
    printf "${BRed} zsh could not be found. Please install zsh before running this script.\n"
    exit 1
fi

WD=$(pwd)
# Check if the script is run in the correct directory
if [[ $WD != *"Libly"* ]]; then
    printf "\033[1;31m This script must be run in the Libly directory. Please run it in the Libly directory.\n"
    exit 1
fi

# go back to the parent directory if we're in the deployment subdirectory
if [[ $WD == *"deployment"* ]]; then
    cd ..
    WD=$(pwd)
fi

set -e

printf "${BBlue} This script will set up the server for you. \n\n"
printf "${BYellow} Please don't skip any inputs, or interrupt the script. Avoid putting '@' sign in mysql credentials ${Color_Off} \n\n"
printf "${BYellow} If you don't understand something, please look at the documentation. \n\n"
printf "${Color_Off} Here we go! \n\n"

read -p "Enter the server domain name: " server_domain
read -p "Enter the mysql username: " mysql_username
read -p "Enter the mysql password: " mysql_password
read -p "Enter the mysql database name: " mysql_database
read -p "Enter the admin email: " admin_email
read -p "Enter the admin password: " admin_password
read -p "Enter the Brevo user ID: " brevo_user_id
read -p "Enter the Brevo API key: " brevo_api_key
read -p "Enter the Brevo sender email: " brevo_sender_email
read -p "Enter the Flask secret key: " flask_secret_key

# put the inputs in an array
inputs=("$server_domain" "$mysql_username" "$mysql_password" "$mysql_database" "$admin_email" "$admin_password" "$brevo_user_id" "$brevo_api_key" "$brevo_sender_email" "$flask_secret_key")

# check if the inputs are empty
for input in "${inputs[@]}"; do
    if [[ -z $input ]]; then
        printf "\033[1;31mMissing arguments. Exiting script with failure...\n"
        printf "${Color_Off}Usage: \t server_setup.sh <Server domain> <MySQL username> <MySQL password> <MySQL database name> <Admin username> <Admin password> <Brevo user ID> <Brevo API key> <Brevo sender email> <Flask secret key>\n"
        exit 1
    fi
done

echo -e "\n\n\033[1;33mYou have 10 seconds to verify the variables you entered:"

printf "${BCyan}\t Server Domain name: ${Color_Off} \t %s \n" "$server_domain"
printf "${BCyan}\t MySQL username: ${Color_Off} \t %s \n\t MySQL password: ${Color_Off} \t %s \n\t MySQL database name: ${Color_Off} \t %s \n" "$mysql_username" "$mysql_password" "$mysql_database"
printf "${BCyan}\t Admin User: ${Color_Off} \t %s \n\t Admin User (%s) password: ${Color_Off} \t %s \n" "$admin_email" "$admin_email" "$admin_password"
printf "${BCyan}\t Brevo user ID: ${Color_Off} \t %s \n\t Brevo API key: ${Color_Off} \t %s \n\t Brevo sender email: ${Color_Off} \t %s \n" "$brevo_user_id" "$brevo_api_key" "$brevo_sender_email"
printf "${BCyan}\t Flask secret key: ${Color_Off} \t %s \n\n" "$flask_secret_key"

sleep 10

sudo mkdir -p /var/log/libly
sudo chown ubuntu:www-data /var/log/libly

nginx_conf=\
"
# Default server configuration

server {
        listen 80 default_server;
        listen [::]:80 default_server;

        server_name $server_domain; # change the domain if any domain changes have occured

        add_header X-Served-By '$server_domain';

        client_max_body_size 100M;

        location /api/ {
                include proxy_params;
                proxy_pass http://0.0.0.0:5000/api/;
        }

        location / {
                include proxy_params;
                proxy_pass http://0.0.0.0:5050/;
        }

        location /static/ {
                include proxy_params;
                proxy_pass http://0.0.0.0:5050;
        }

        location /mail/ {
                include proxy_params;
                proxy_pass http://0.0.0.0:3000/;
        }
}
" # make sure to change the server names or domains accordingly

source ~/.Libly/venv/bin/activate

libly_api=\
"
[Unit]
Description=Gunicorn instance to serve the Flask based API
After=network.target mysql.service
Requires=mysql.service

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$WD/
Environment=\"MYSQL_DB=$mysql_database\"
Environment=\"MYSQL_USER=$mysql_username\"
Environment=\"MYSQL_PASSWORD=$mysql_password\"
ExecStart=$HOME/.Libly/venv/bin/python3 -m gunicorn --workers 2 --bind 0.0.0.0:5000 --access-logfile /var/log/libly/libly_api.log --error-logfile /var/log/libly/libly_api-error.log flask_api.v1.app:app

[Install]
WantedBy=multi-user.target
"

node_api_service=\
"
[Unit]
Description=Node instance to serve the node API
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$WD/node_api/
Environment=\"NODE_PATH=/usr/lib/node_modules\"
Environment=\"SMTP_USERNAME=$brevo_user_id\"
Environment=\"SMTP_PASSWORD=$brevo_api_key\"
Environment=\"SMTP_SENDER=$brevo_sender_email\"
ExecStart=/usr/bin/node $WD/node_api/app.js
StandardOutput=append:/var/log/libly/node_api-output.log
StandardError=append:/var/log/libly/node_api-error.log

[Install]
WantedBy=multi-user.target
"

libly_web=\
"
[Unit]
Description=Gunicorn instance to serve the web server
After=network.target flask_api.service

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$WD/
Environment=\"API_HOST=$server_domain\"
Environment=\"FLASK_SECRET_KEY=$flask_secret_key\"
ExecStart=$HOME/.Libly/venv/bin/python3 -m gunicorn --workers 2 --bind 0.0.0.0:5050 --access-logfile /var/log/libly/libly_web.log --error-logfile /var/log/libly/libly_web-error.log web_client.app:app

[Install]
WantedBy=multi-user.target
"

echo "$nginx_conf" | sudo tee /etc/nginx/sites-available/default > /dev/null
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
echo "$libly_api" | sudo tee /etc/systemd/system/libly_api.service > /dev/null
echo "$node_api_service" | sudo tee /etc/systemd/system/node_api.service > /dev/null
echo "$libly_web" | sudo tee /etc/systemd/system/libly_web.service > /dev/null

printf "${BYellow} ... \nThe certbot script which is going to set up your https is going to start \n"
printf "${BYellow} ... \nPlease follow the prompts carefully. And make sure your DNS is set up correctly before starting\n\n${Color_Off}"
sleep 5

sudo certbot --nginx

# Then set up mysql
# Edit the mysql setup script to include the mysql username and password
printf "${BPurple} Setting up mysql... "
sed -i "s#user#$mysql_username#" "setup_mysql_dev.sql"
sed -i "s#pwd#$mysql_password#" "setup_mysql_dev.sql"
sed -i "s#db#$mysql_database#" "setup_mysql_dev.sql"
printf "${BGreen} done!\n"

printf "${BPurple} Adding admin user to DB..."

# First drop the environment variables into the environment
export ADMIN_EMAIL="$admin_email"
export ADMIN_PASSWORD="$admin_password"
export MYSQL_DB="$mysql_database"
export MYSQL_USER="$mysql_username"
export MYSQL_PASSWORD="$mysql_password"
export PATH="$PATH:/home/ubuntu/.local/bin"

cat setup_mysql_dev.sql | sudo mysql -u root

# Call the admin maker python script
python3 "setup_admin.py"
printf "${BGreen} done!\n\n${Color_Off}"

sed -i "s#undefined#'$server_domain'#" "$WD/web_client/static/scripts/API_HOST.js"

sudo systemctl daemon-reload
sudo systemctl enable mysql
sudo systemctl enable libly_api
sudo systemctl enable node_api
sudo systemctl enable libly_web
sudo service mysql start
sudo service nginx start
sudo service libly_api start
sudo service node_api start
sudo service libly_web start

sudo systemctl status libly_api node_api libly_web nginx --no-pager

# Print Success
printf "${BGreen}\n\nLibly has been successfully deployed on your server! \n\n"
printf "${BPurple}Please make sure to check the logs for any errors. \n\n"
printf "${Color_Off}App running at https://%s\n\n" "$server_domain"
