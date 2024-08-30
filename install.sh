#!/bin/bash
#RAMBO TORRENT BOX SETUP SCRIPT. [DEBIAN 9+]
#Installs Deluge Daemon and Web-UI

usr=$1 #username

#Make sure arguments are passed
if [ $# -lt 1 ]; then
    printf "Usage: install.sh user\n"
    exit 1
fi

#Bash styling
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"
delay=1 # delay in seconds after showing step

printf "$ST Updating OS & Installing Deluge \n $SB"
sleep $delay
apt update && apt upgrade -y
apt install deluged deluge-web git curl pip -y

printf "$ST Configuring Deluge \n $SB"
sleep $delay

#Creating deluge user and group
adduser --group deluge
gpasswd -a root deluge
gpasswd -a $usr deluge

#creating download folders & setting perms
mkdir /mnt/deluge
chmod 774 /mnt/deluge
chown -R deluge:deluge /mnt/deluge

#Creating system service for deluge
touch /etc/systemd/system/deluged.service
echo "[Unit]" >> /etc/systemd/system/deluged.service
echo "Description=Deluge Bittorrent Client Daemon" >> /etc/systemd/system/deluged.service
echo "After=network-online.target" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "[Service]" >> /etc/systemd/system/deluged.service
echo "Type=simple" >> /etc/systemd/system/deluged.service
echo "User=deluge" >> /etc/systemd/system/deluged.service
echo "Group=deluge" >> /etc/systemd/system/deluged.service
echo "UMask=007" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "ExecStart=/usr/bin/deluged -d" >> /etc/systemd/system/deluged.service
echo "" >> /etc/systemd/system/deluged.service
echo "Restart=on-failure" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "# Configures the time to wait before service is stopped forcefully." >> /etc/systemd/system/deluged.service
echo "TimeoutStopSec=300" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "[Install] " >> /etc/systemd/system/deluged.service
echo "WantedBy=multi-user.target " >> /etc/systemd/system/deluged.service

#Starting deluge service
systemctl start deluged
systemctl enable deluged

#Creating system service for deluge web interface
touch /etc/systemd/system/deluge-web.service
echo "[Unit]" >> /etc/systemd/system/deluge-web.service
echo "Description=Deluge Bittorrent Client Web Interface" >> /etc/systemd/system/deluge-web.service
echo "After=network-online.target" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "[Service]" >> /etc/systemd/system/deluge-web.service
echo "Type=simple" >> /etc/systemd/system/deluge-web.service
echo "User=deluge" >> /etc/systemd/system/deluge-web.service
echo "Group=deluge" >> /etc/systemd/system/deluge-web.service
echo "UMask=027" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "ExecStart=/usr/bin/deluge-web -d" >> /etc/systemd/system/deluge-web.service
echo "" >> /etc/systemd/system/deluge-web.service
echo "Restart=on-failure" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "[Install] " >> /etc/systemd/system/deluge-web.service
echo "WantedBy=multi-user.target " >> /etc/systemd/system/deluge-web.service

#Starting web service
systemctl start deluge-web
systemctl enable deluge-web

if [ -f /usr/bin/pushover ]; then
    pushover "Deluge Setup Complete"
fi

printf "\n${BLUE}----------------------------------------------------------------------\n\n"
printf "Setup Complete! \n$SB"