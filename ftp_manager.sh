#!/bin/bash

# ==========================================
# FTP Server Management Tool
# CentOS
# ==========================================

FTP_SERVICE="vsftpd"
FTP_CONFIG="/etc/vsftpd/vsftpd.conf"

show_menu() {

    clear

    echo "======================================"
    echo "       FTP SERVER MANAGEMENT"
    echo "======================================"
    echo "1. Install FTP Server"
    echo "2. Start FTP Server"
    echo "3. Stop FTP Server"
    echo "4. Restart FTP Server"
    echo "5. Show FTP Status"
    echo "6. Add FTP User"
    echo "7. Delete FTP User"
    echo "8. List FTP Users"
    echo "9. Show Server IP"
    echo "10. Show FTP Logs"
    echo "0. Exit"
    echo "======================================"
}

install_ftp() {

    echo "Installing vsftpd..."

    sudo dnf install vsftpd -y

    sudo systemctl enable vsftpd
    sudo systemctl start vsftpd

    sudo firewall-cmd \
        --permanent \
        --add-service=ftp

    sudo firewall-cmd --reload

    echo "FTP Server installed successfully."
}


start_ftp() {
    sudo systemctl start vsftpd
    echo "FTP Server started."
}

stop_ftp() {
    sudo systemctl stop vsftpd
    echo "FTP Server stopped."
}

restart_ftp() {
    sudo systemctl restart vsftpd
    echo "FTP Server restarted."
}

status_ftp() {
    sudo systemctl status vsftpd --no-pager
}

add_ftp_user() {

    read -p "Enter FTP username: " username

    if id "$username" &>/dev/null; then

        echo "User $username already exists."

        return
    fi

    sudo useradd -m "$username"

    sudo passwd "$username"

    sudo mkdir -p "/home/$username/ftp"

    sudo chown -R \
        "$username:$username" \
        "/home/$username/ftp"

    echo "FTP user '$username' created successfully."
}

delete_ftp_user() {

    read -p "Enter username to delete: " username

    if ! id "$username" &>/dev/null; then

        echo "User does not exist."

        return
    fi

    read -p \
        "Delete $username and home directory? (y/n): " \
        confirm

    if [[ "$confirm" == "y" ]]; then

        sudo userdel -r "$username"

        echo "User deleted."

    else

        echo "Operation cancelled."

    fi
}

list_ftp_users() {

    echo "===== FTP Users ====="

    awk -F: '$3 >= 1000 {
        print $1 "  ->  " $6
    }' /etc/passwd
}

show_ip() {

    echo "===== Server IP ====="

    hostname -I
}

show_logs() {

    sudo journalctl \
        -u vsftpd \
        -n 30 \
        --no-pager
}


while true
do

    show_menu

    read -p "Choose an option: " choice

    case $choice in

        1)
            install_ftp
            ;;

        2)
            start_ftp
            ;;

        3)
            stop_ftp
            ;;

        4)
            restart_ftp
            ;;

        5)
            status_ftp
            ;;

        6)
            add_ftp_user
            ;;

        7)
            delete_ftp_user
            ;;

        8)
            list_ftp_users
            ;;

        9)
            show_ip
            ;;

        10)
            show_logs
            ;;

        0)
            echo "Exit."
            exit 0
            ;;

        *)
            echo "Invalid option."
            ;;

    esac

    echo
    read -p "Press Enter to continue..."

done