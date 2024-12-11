#!/bin/bash
#fancy colors and font options (a work in progress)
NORMAL=''
GREEN=''
RED=''
ITALIC=''
BOLD=''
if tty -s; then
  NORMAL="$(tput sgr0)"
  GREEN=$(tput setaf 2)
  RED="$(tput setaf 1)"
  BOLD=$(tput bold)
  ITALIC=$(tput sitm)
fi

#Set some options for the kiosk/signage
# We use a google slide with options like this: embed?&start=true&loop=true&rm=minimal&delayms=10000
# Prompt the user for their choice
echo "Please select an option:"
echo "1. LOCATION-1"
echo "2. LOCATION-2"
echo "3. LOCATION-3"
echo "4. LOCATION-4"
echo "5. LOCATION-5"

read -p "Enter your choice (1-5): " choice

# Validate the input
while [[ ! $choice =~ ^[1-5]$ ]]; do
    echo "Invalid choice. Please enter a number between 1 and 5."
    read -p "Enter your choice (1-5): " choice
done

# Set the URL based on the choice
case $choice in
    1) URL="https://your.site/kiosk1" ;;
    2) URL="https://your.site/kiosk2" ;;
    3) URL="https://your.site/kiosk3" ;;
    4) URL="https://your.site/kiosk4" ;;
    5) URL="https://your.site/kiosk5" ;;
esac


# be new
apt-get update

# get software
apt-get install \
	unclutter \
    xorg \
    chromium \
    openbox \
    lightdm \
    locales \
    -y

# dir
mkdir -p /home/kiosk/.config/openbox

# create group
groupadd kiosk

# create user if not exists
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash 

# rights
chown -R kiosk:kiosk /home/kiosk

# remove virtual consoles
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF
#disable screen blanking for signage solution
cat /etc/X11/xorg.conf.d/10-serverflags.conf <<EOF
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "DPMS" "false"
EndSection
EOF

# create config
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# create autostart
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash
# Prevent screen blanking and power saving
xset s off           # Disable screen saver
xset s noblank       # Disable screen blanking
xset -dpms           # Disable power management
#hide mouse
unclutter -idle 0.1 -grab -root &
#pause for a second to avoid "no internet error on chromium launch"
sleep 5
#set chromium options
while :
do
  xrandr --auto
  chromium \
    --no-first-run \
    --start-fullscreen \
    --disable-translate \
    --disable-infobars \
    --disable-features=TranslateUI,AutofillKeyPopup,PasswordGeneration \
    --disable-suggestions-service \
    --disable-sync \
    --disable-save-password-bubble \
    --disable-crash-reporter \
    --disable-session-crashed-bubble \
    --incognito \
    --disable-application-cache \
    --disable-cache \
    --disable-offline-load-stale-cache \
    --disk-cache-size=0 \
    --media-cache-size=0 \
    --kiosk "$URL"
  sleep 5
done &
EOF

# Display the current hostname
echo "The current hostname is: $(hostname)"

# Ask if the hostname should be changed
read -p "${GREEN}${BOLD}Would you like to change the hostname? (y/n):${NORMAL} " response

if [[ "$response" == "y" || "$response" == "Y" ]]; then
  # Prompt for the new hostname
  read -p "Enter the new hostname: " new_hostname
  
  # Set the new hostname
  hostnamectl set-hostname "$new_hostname"
  
  # Update /etc/hosts file to map the new hostname to 127.0.1.1
  sed -i "s/127.0.1.1 .*/127.0.1.1 $new_hostname/" /etc/hosts
  
  echo "${GREEN}${BOLD}Hostname changed to $new_hostname. A reboot might be required for all changes to take effect."
else
  echo "${RED}${BOLD}Hostname not changed.${NORMAL}"
fi

# Install Zabbix agent2 and add to your zabbix server to monitor device.
# change <ipaddress> to your server of comment this all out.
apt-get install zabbix-agent2 -y
# Configure Zabbix agent to connect to the Zabbix server
sed -i "s/^Server=.*/Server=<ipaddress>/" /etc/zabbix/zabbix_agent2.conf
sed -i "s/^ServerActive=.*/ServerActive=<ipaddress>/" /etc/zabbix/zabbix_agent2.conf

# Set the hostname for the Zabbix agent to match the current system hostname
current_hostname=$(hostname)
sed -i "s/^Hostname=.*/Hostname=$current_hostname/" /etc/zabbix/zabbix_agent2.conf

# Restart Zabbix agent to apply configuration changes
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

echo "${GREEN}${BOLD}Done!"
