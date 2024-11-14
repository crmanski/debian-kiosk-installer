#!/bin/bash
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

echo "Done!"
