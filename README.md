# Kiosk installer for Debian based Linux distros
Small installer script to setup a minimal kiosk with Chromium for Debian based Linux distros. This installer is heavily based on the excellent [instructions by Will Haley](http://willhaley.com/blog/debian-fullscreen-gui-kiosk/).
*--Forked for Signage purposes in December 2024 by Craig
## Usage
* Setup a minimal Debian https://www.debian.org/distrib/ without display manager,  [32-bit PC netinst iso](https://cdimage.debian.org/debian-cd/current/i386/iso-cd/debian-12.8.0-i386-netinst.iso) / [64-bit PC netinst iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso)
* Login as root or with root permissions
* Download this installer, place it on an internal webserver, modify as needed, make it executable and run it

Example...
  ```shell
  wget https://raw.githubusercontent.com/crmanski/debian-kiosk-installer/master/kiosk-installer.sh; chmod +x kiosk-installer.sh; ./kiosk-installer.sh
  ```

If you are installing to a Raspberry Pi, change chromium to chromium-browser in the install script (both in apt line and startup command)

## What will it do?
It will create a normal user `kiosk`, install software (check the script) and setup configs (it will backup existing) so that on reboot the kiosk user will login automaticaly and run chromium in kiosk mode with one url. It will also hide the mouse. 

## Change the location and url(s)
Change the location and url variables at at the top and modify as needed.

## Is it secure?
No. Although it will run as a normal user (and I suggest you don't leave a keyboard and mouse hanging around), there will be the possibility of plugin' in a mini keyboard, opening a terminal and opening some nasty things. Security is your thing ;-) 
