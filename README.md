# Deluge-Installer

Deluge install script for headless debian based linux servers.
Installs deluge daemon and deluge web interface. 
It also creates a service that starts at boot.

## Prepare system

``apt update && apt dist-upgrade -y && apt install git -y``


## Clone the installer

``git clone https://rigslab.com/Rambo/Deluge-Installer.git``


## Make executable

``chmod +x ./Deluge-Installer/install.sh``


## Run Installer

``./Deluge-Installer/install.sh user*``

*The user argument is optional. It adds your user to the deluge group so you can manage the downloads.*

Access your web ui http://server_ip:8112

Default password is ``deluge``

The download folder should be set to /mnt/deluge