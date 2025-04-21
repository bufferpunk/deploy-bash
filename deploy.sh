#!/usr/bin/env bash
## ./deploy.sh
## Deploys a web app to given SERVERS
## Copyright (C) 2025 Buffer Park. All rights reserved.
## MIT License

set -e
trap 'echo -e "\n${BRed}Error: An error occurred during deployment. Please check your inputs and try again.${Color_Off}"' ERR

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/awesome.conf" # For colors and Usage message

cd ..

for i in "$@"; do
    if [[ $i =~ ^--config= ]]; then
        config="${i#*=}"
        old="$OLDPWD"
        if [ -f "$old/$config" ]; then
            source "$old/$config";
            echo -e "${Cyan}Using configuration from $config file.${Color_Off}";
            IFS=',' read -r -a SERVERS <<< "$SERVERS";
            IFS=',' read -r -a SERVICES <<< "$SERVICES";
        else
            echo -e "${BRed}Error: Configuration file '$config' not found.${Color_Off} Falling back to command line arguments."
            exit 1
        fi
    elif [[ $i =~ ^--servers=\[(.*)\]$ ]]; then
        IFS=',' read -r -a SERVERS <<< "${BASH_REMATCH[1]}"
    elif [[ $i =~ ^--services=\[(.*)\]$ ]]; then
        IFS=',' read -r -a SERVICES <<< "${BASH_REMATCH[1]}"
    elif [[ $i =~ ^--type= ]]; then
        TYPE="${i#*=}"
        if [[ "$TYPE" != "domain" && "$TYPE" != "ip" ]]; then
            echo -e "${BRed}Error: Invalid TYPE '$TYPE'. Please use 'domain' or 'ip'. ${Color_Off}"
            exit 1
        fi
    elif [[ $i =~ ^--rollback= ]]; then
        ROLLBACK="${i#*=}"
        if ! [[ "$ROLLBACK" =~ ^[0-9]+$ ]]; then
            echo -e "${BRed}Error: Invalid ROLLBACK value '$ROLLBACK'. Please provide a number.${Color_Off}"
            exit 1
        fi
        echo -e "${BCyan}You included the rollback option '$ROLLBACK'.${Color_Off}"
    elif [[ $i =~ ^--deploy-dir= ]]; then
        DEPLOY_DIR="${i#*=}"
        export DEPLOY_DIR="$DEPLOY_DIR"
    elif [[ $i =~ ^--setup= ]]; then
        setup="${i#*=}"
        if [[ "$setup" != "full" && "$setup" != "only" ]]; then
            echo -e "${BRed}Error: Invalid setup option '$setup'. Please use 'full' or 'only'. ${Color_Off}"
            exit 1
        else
            echo -e "${BCyan}You included the setup option '$setup'.${Color_Off}"
            printf "${BCyan}How many commands do you want to run on the remote server(s)?: ${Color_Off}"
            read -r NUMBER
            SETUP_COMMAND=""
            if ! [[ "$NUMBER" =~ ^[0-9]+$ ]]; then
                echo -e "${BRed}Error: Invalid number of commands '$NUMBER'. Please provide a number.${Color_Off}"
                exit 1
            fi
            for ((i=1; i<=NUMBER; i++)); do
                printf "${BCyan}Enter command $i: ${Color_Off}"
                read -r command
                if [[ -z "$command" ]]; then
                    echo -e "${BRed}Error: Command cannot be empty. Please provide a valid command.${Color_Off}"
                    exit 1
                fi
                SETUP_COMMAND="$SETUP_COMMAND$command && "
                echo -e "${Green}Command $i added: $command${Color_Off}"
            done
            SETUP_SSH_USERCOMMAND="${SETUP_COMMAND%&& }" # Remove trailing '&&'
            echo -e "${Green}Setup command set to: $SETUP_COMMAND${Color_Off}"
        fi
    elif [[ $i =~ ^--project= ]]; then
        PROJECT_NAME="${i#*=}"
        export PROJECT_NAME="$PROJECT_NAME"
        if [ ! -d "$PROJECT_NAME" ]; then
            echo -e "${BRed} Could not find $PROJECT_NAME in $(pwd) ${Color_Off}"
            exit 1
        fi

    elif [[ $i =~ ^--keep= ]]; then
        KEEP="${i#*=}"
        if ! [[ "$KEEP" =~ ^[0-9]+$ ]]; then
            echo -e "${BRed}Error: Invalid KEEP value '$KEEP'. Please provide a number.${Color_Off}"
            exit 1
        fi
    elif [[ $i =~ ^--help$ || $i =~ ^-h$ ]]; then
        echo -e "$Usage"
        exit 0
    elif ! [[ $i =~ ^-- ]]; then
        echo -e "${BRed}Error: Invalid argument format: '$i'. ${Color_Off}"
        echo -e "$Usage"
        exit 1
    fi
done

KEEP=${KEEP:-5}

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${BYellow}WARNING: PROJECT_NAME is not set in your environment. Falling back to user input. ${Color_Off}\n"
    echo -e "${BCyan}What is your project name?${Color_Off}"
    read -r PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${BRed}Error: No project name provided. Exiting...${Color_Off}"
        exit 1
    fi
    export PROJECT_NAME="$PROJECT_NAME"
    if [ ! -d "$PROJECT_NAME" ]; then
        echo -e "${BRed}Could not find '$PROJECT_NAME' in $(pwd) ${Color_Off}"
        exit 1
    fi
    echo -e "${Cyan}You can set the PROJECT_NAME environment variable in your shell profile to avoid this prompt in the future or pass --project in flags.${Color_Off}"
    echo -e "${Cyan}Please note that the project name must match the name of the folder in which the project is located.${Color_Off}"
fi

echo -e "${BGreen}Welcome to the ${BBlue}${PROJECT_NAME}'s ${BGreen}Deployment!${Color_Off}\n"

# Check if host command is available
if ! command -v host &> /dev/null
then
    echo -e "${BRed}Error:${Color_Off} host command not found. Installing dnsutils..."
    sudo apt-get install -y dnsutils
fi

# check length
if [ ${#SERVERS[@]} -lt 1 ]; then
    echo -e "${BRed}Error:${Color_Off} ${Red}No servers provided. Please provide a list of servers in the format: servers=[server1,server2,...]${Color_Off}"
    exit 1
fi

if [ "$TYPE" == "domain" ]; then
    printf "${BYellow}Warning:${Color_Off} ${Yellow}You are using domain names. Make sure they are valid and reachable.${Color_Off}\n${Cyan}Checking domain names... ${Color_Off}"
    for s in "${SERVERS[@]}"; do
        if ! host "$s" &> /dev/null; then
            echo -e "${BRed}Error:${Color_Off} The domain name ${BRed}'$s'${Color_Off} you provided is invalid or unreachable.\nPlease check your domain names. Exiting..."
            exit 1
        fi
    done
    echo -e "${Green}Done! All domain names are valid.${Color_Off}\n"
else
    # Check for valid IP addresses
    for s in "${SERVERS[@]}"; do
        if ! [[ "$s" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
            echo -e "${BRed}Error:${Color_Off} Invalid IP address ${BRed}'$s'${Color_Off}. Please provide valid IP addresses."
            exit 1
        fi
    done
fi

restart_services=""
for i in "${SERVICES[@]}"; do
    if [[ "$i" =~ ^[a-zA-Z0-9_]+$ ]]; then
        restart_services="$restart_services $i"
    else
        echo -e "${BRed}Error:${Color_Off} ${Red}Invalid service name '$i'. Only alphanumeric characters and underscores are allowed.${Color_Off}"
        exit 1
    fi
done

if [ -n "$ROLLBACK" ]; then
    if [[ -z "$SERVERS" || -z "$SERVICES" ]]; then
        echo -e "${BRed}Error: Please provide servers for rollback and services to restart ${Color_Off}"
        exit 1
    fi
    for i in "${SERVERS[@]}"; do
        echo -e "${BBlue}Rolling back on server: ${BYellow}\t$i\t...\n${Color_Off}"
        ssh -i "$SSH_KEY" "$SSH_USER@$i" "bash -c '
            cd $DEPLOY_DIR/
            rm -rf ../current
            f=\$(ls -ut | grep "$PROJECT_NAME" | head -n +$((ROLLBACK)) | tail -n +$((ROLLBACK)))
            echo -e \"${Cyan}Rolling back to version: ${BCyan}\$f${Color_Off}\n\"
            ln -s \$(readlink -f \$f) ../current
            ls -l .. | grep current
            sudo systemctl restart $restart_services
            echo -e \"${Cyan}Service statuses after restart:${Color_Off}\n\"
            sudo systemctl status $restart_services --no-pager
            echo -e \"${Green}Rollback completed on server name: $i.${Color_Off}\n\"
        '"
    done
    echo -e "${BCyan}Done. Bye!${Color_Off}"
    exit 0
fi

echo -e "\n${BYellow}Please note that this script does not provide full graceful error handling, so that you don't live with a broken app.${Color_Off}\n"
if [ "$setup" == "only" ]; then
    for i in "${SERVERS[@]}"; do
        echo -e "${Green}Skipping deployment and going for server setup. This will fail if there is no deployed version.${Color_Off}"
        echo -e "${BBlue}Running Setup command: ${Cyan} $SETUP_COMMAND ...${Color_Off}\n"
        runcommand=$([[ "$*" =~ (^|[[:space:]])--npm($|[[:space:]]) ]] && echo "$SETUP_COMMAND && cd $DEPLOY_DIR/../current/$NODE_HOME && npm install" || echo "$SETUP_COMMAND")
        ssh -i "$SSH_KEY" "$SSH_USER@$i" "bash -c '
            $runcommand
            if sudo systemctl status $restart_services >/dev/null 2>&1; then
                echo \"✅ Services are running fine. Restarting: $restart_services\" && sudo systemctl restart $restart_services
                echo -e \"${Green}Setup completed successfully on server name: $i.${Color_Off}\"
            else
                echo \"❌ Some services might be dead or unavailable. Please check your setup. Full setup failed.\"
            fi'"

    done
    echo -e "\n${BCyan}Done. Bye!${Color_Off}"
    exit 0
fi

inputFile="$PROJECT_NAME"
dtime="$(date +'%Y%m%d%H%M%S')"
file="$inputFile$dtime"

if [ ! -d "$inputFile" ]; then
    echo -e "${BRed}Error: Input directory '$inputFile' does not exist.${Color_Off}"
    exit 1
fi

# Countdown
echo -e "${BCyan}After this operation, the deployed version will be stored in the folder 'versions/'"
echo -e "Deployment will commence in 10 seconds. Check if you entered correct information. \nPress ctrl c, to cancel if you made a mistake.${Color_Off}\n"

spinner="/|\\-/"
for ((j=10; j>0; j--)); do
    echo -ne "${Yellow}Starting deployment in $j seconds... ${spinner:$((j%4)):1} \r"
    sleep 1
done
echo -e "\n"

# Display archive name and deployment servers
echo -e "${Cyan}Your new archive will be named:${Color_Off}\t$file"

echo -e "${Cyan}Deploying to the following servers:${Color_Off}\n"
for i in "${SERVERS[@]}"; do
    printf "\t%s\n" "$i" 
done

# Create versions directory if it doesn't exist
if [ ! -d "$inputFile/versions" ]; then
    mkdir "$inputFile/versions/"
fi

# Create and transfer archive, then deploy to servers
tar --exclude="versions" --exclude=".git" -czf "$inputFile/versions/$file.tgz" -C "$inputFile" .
echo -e "${Cyan}Archive created successfully. Beginning deployment...${Color_Off}\n"

for i in "${SERVERS[@]}"; do
	(
    echo -e "${BBlue}Deploying on server: ${BYellow}\t$i\t...\n${Color_Off}"
    if [[ "$*" =~ (^|[[:space:]])--apt-update($|[[:space:]]) ]]; then
        echo -e "${Cyan}Running apt-get update...${Color_Off}"
        ssh -i "$SSH_KEY" "$SSH_USER@$i" "sudo apt-get update"
        echo -e "${Cyan}Server updated successfully.${Color_Off}"
    fi

    scp -i "$SSH_KEY" "$inputFile/versions/$file.tgz" "$SSH_USER@$i:/tmp/"
    echo ""
    echo -e "${Green}Copied archive file to server:${Color_Off}\t$i in directory:\t/tmp/\n"
    echo -e "${Blue}Extracting archive to:${Color_Off}\t$DEPLOY_DIR/ ..."
    ssh -i "$SSH_KEY" "$SSH_USER@$i" "mkdir -p $DEPLOY_DIR/new && tar -xzf /tmp/$file.tgz -C $DEPLOY_DIR/new && mv $DEPLOY_DIR/new $DEPLOY_DIR/$file"
    echo -e "${Cyan}Here are the new contents of the releases directory:${Color_Off}\n"

    ssh -i "$SSH_KEY" "$SSH_USER@$i" "sudo rm -rf $DEPLOY_DIR/new/ && ls $DEPLOY_DIR/ | sed 's/^/\t\t\t/' && sudo rm -rf $DEPLOY_DIR/../current && ln -s $DEPLOY_DIR/$file $DEPLOY_DIR/../current"
    echo -e "\n${Green}Finished making a symbolic link for the new release. Deleting old releases...${Color_Off}\n"
    ssh -i "$SSH_KEY" "$SSH_USER@$i" "cd $DEPLOY_DIR/ && ls -ut | grep "$PROJECT_NAME" | tail -n +$((KEEP + 1)) | xargs rm -rf"
    ls "$PROJECT_NAME/versions" -ut | grep "$PROJECT_NAME" | tail -n +$((KEEP + 1)) | xargs rm -rf

    echo -e "${Cyan}Deleted old releases, keeping the last $KEEP versions.${Color_Off}\n"
    if [ "$setup" == 'full' ]; then
        echo -e "${Cyan}Running Setup command...${Black} ${SETUP_COMMAND}${Color_Off}"
        ssh -i "$SSH_KEY" -tt "$SSH_USER@$i" "$SETUP_COMMAND"
        echo -e "${Cyan}Setup completed successfully.${Color_Off}\n"
    fi

    if [[ "$*" =~ (^|[[:space:]])--npm($|[[:space:]]) ]]; then
        echo -e "${Cyan}Running npm install on the latest version...${Color_Off}"
        ssh -i "$SSH_KEY" "$SSH_USER@$i" "cd $DEPLOY_DIR/$file/$NODE_HOME && npm install"
        echo -e "${Cyan}Npm install was a success.${Color_Off}\n"
    fi

    define_api=$([ -n "$JSHOST" ] && echo "sed -i 's#undefined#\\\"$i\\\"#' $JSHOST" || echo "echo 'No JSHOST Defined. Skipping modification.'")
    ssh -i "$SSH_KEY" "$SSH_USER@$i" bash <<EOF
    cd $DEPLOY_DIR/$file/ && sudo rm -rf /tmp/$file.tgz
    $define_api
    if sudo systemctl status $restart_services >/dev/null 2>&1; then
        echo -e "${BGreen}✅${Color_Off} Services are running fine. Restarting: $restart_services"
        sudo systemctl restart $restart_services && echo -e "${BGreen}✅${Color_Off} Services restarted successfully."
    else
        echo "❌ Some services might be dead or unavailable. Please check your setup."
    fi
EOF

    echo -e "${Green}Your newest app release ($file) is now live on -> ($i)!${Color_Off}\nYou can visit: $i/ to use app if the services are set up correctly.\n"
	) &
done
wait

echo -e "${BGreen}Deployment complete${Color_Off}"
