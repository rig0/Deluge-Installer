#!/bin/bash
# RAMBO TORRENT BOX SETUP SCRIPT. [DEBIAN 9+]
# Installs Deluge Daemon and Web-UI

usr=$1 # username to add to deluge group (optional argument)
delugeUsr="deluge"

# Bash styling
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"
delay=1 # delay in seconds after showing step

printf "$ST Updating OS & Installing Deluge \n $SB"
sleep $delay
apt update && apt dist-upgrade -y
apt install deluged deluge-web -y

printf "$ST Configuring Deluge \n $SB"
sleep $delay

# Creating deluge user and group
adduser --system --group $delugeUsr

# Check if media group exists
if getent group "media" > /dev/null 2>&1; then
    echo "Group 'media' already exists. Skipping step"
else
    groupadd media
fi

# Add deluge user to media group
usermod -aG media $delugeUsr

# Add user to deluge and media group
if [ $# -lt 1 ]; then
    usermod -aG media $usr
    usermod -aG $delugeUsr $usr
fi

# Creating download folders & setting permssions that play nice with servarr stack
mkdir /mnt/deluge
chmod 774 /mnt/deluge
chown -R $delugeUsr:media /mnt/deluge

printf "$ST Creating system services \n $SB"
# Creating system service for deluge
touch /etc/systemd/system/deluged.service
echo "[Unit]" >> /etc/systemd/system/deluged.service
echo "Description=Deluge Bittorrent Client Daemon" >> /etc/systemd/system/deluged.service
echo "After=network-online.target" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "[Service]" >> /etc/systemd/system/deluged.service
echo "Type=simple" >> /etc/systemd/system/deluged.service
echo "User=$delugeUsr" >> /etc/systemd/system/deluged.service
echo "Group=$delugeUsr" >> /etc/systemd/system/deluged.service
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

# Creating system service for deluge web interface
touch /etc/systemd/system/deluge-web.service
echo "[Unit]" >> /etc/systemd/system/deluge-web.service
echo "Description=Deluge Bittorrent Client Web Interface" >> /etc/systemd/system/deluge-web.service
echo "After=network-online.target" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "[Service]" >> /etc/systemd/system/deluge-web.service
echo "Type=simple" >> /etc/systemd/system/deluge-web.service
echo "User=$delugeUsr" >> /etc/systemd/system/deluge-web.service
echo "Group=$delugeUsr" >> /etc/systemd/system/deluge-web.service
echo "UMask=027" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "ExecStart=/usr/bin/deluge-web -d" >> /etc/systemd/system/deluge-web.service
echo "" >> /etc/systemd/system/deluge-web.service
echo "Restart=on-failure" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "[Install] " >> /etc/systemd/system/deluge-web.service
echo "WantedBy=multi-user.target " >> /etc/systemd/system/deluge-web.service

#printf "$ST Changing default download location \n $SB"
# Change the default download location
#sed -i 's#"download_location": "/home/deluge/Downloads"#"download_location": "/mnt/deluge"#' "/home/deluge/.config/deluge/core.conf"
#sed -i 's#"move_completed_path": "/home/deluge/Downloads"#"move_completed_path": "/mnt/deluge"#' "/home/deluge/.config/deluge/core.conf"
#sed -i 's#"torrentfiles_location": "/home/deluge/Downloads"#"torrentfiles_location": "/mnt/deluge"#' "/home/deluge/.config/deluge/core.conf"

printf "$ST Starting services \n $SB"
# Starting deluge service
systemctl start deluged
systemctl enable deluged
# Starting web service
systemctl start deluge-web
systemctl enable deluge-web

#printf "$ST Copying ssh keys to deluge user \n $SB"
# Copy keys over to user
#mkdir /home/deluge/.ssh
#cp -R /root/.ssh/* /home/deluge/.ssh/
#chown -R deluge:deluge /home/deluge/.ssh/
#chmod 700 /home/deluge/.ssh/
#chmod 600 /home/deluge/.ssh/authorized_keys
#chmod 600 /home/deluge/.ssh/id_rsa
#chmod 644 /home/deluge/.ssh/id_rsa.pub
#service sshd restart

if [ -f /usr/bin/pushover ]; then
    pushover "Deluge Setup Complete"
fi

printf "\n${BLUE}----------------------------------------------------------------------\n\n"
printf "Setup Complete! \n$SB"