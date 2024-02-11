#!/bin/bash
# ALT Linux post install script

if lsb_release -cs | grep -qE "Destiny|CaptainFinn|Laertes|Hypericum|Autolycus"; then
	if lsb_release -d | grep -qE "p9|9\."; then
        ver=p9
	fi
    if lsb_release -d | grep -qE "p10|10\."; then
        ver=p10
    fi
else
    echo "Currently only ALT Linux p9 and p10 - SimplyLinux, Workstation and StarterKit MATE are supported!"
    exit 1
fi

is_docker=0
if [ -f /.dockerenv ]; then
    echo "Note: we are running inside Docker container, so some adjustings will be applied!"
    is_docker=1
fi

if [ "$UID" -ne "0" ]
then
    echo "Please run this script as root user with 'sudo -E ./alpis.sh'"
    exit 3
fi

if [ "$(arch)" != "x86_64" ]; then
    echo "Currently only x86_64 CPU architecture is supported!"
    exit 4
fi

echo "Welcome to the ALT Linux post-install script!"
set -e
set -x

# Install updates
rm -vrf /var/lib/apt/lists/*
mkdir -p /var/lib/apt/lists/partial
apt-get update
apt-get dist-upgrade --force-yes -y
apt-get install -f -y

if [ $is_docker == 0 ]; then
  update-kernel -a -f
fi

# add rpm-src
apt-get install -y apt-repo
apt-repo add "$(apt-repo | grep branch | grep 'x86_64 ' | sed 's/^rpm /rpm-src /' | sed 's/debuginfo//g' | sort -u | head -n1)"
apt-repo add "$(apt-repo | grep branch | grep 'noarch ' | sed 's/^rpm /rpm-src /' | sort -u | head -n1)"
## temporary fix for https://bugzilla.altlinux.org/48551
sed -i "s|pub distributions/ALTLinux|pub/distributions/ALTLinux |g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list

# add Autoimports
apt-repo add "rpm http://mirror.yandex.ru/altlinux/autoimports/$ver x86_64 autoimports"
apt-repo add "rpm http://mirror.yandex.ru/altlinux/autoimports/$ver noarch autoimports"
apt-repo add "rpm-src http://mirror.yandex.ru/altlinux/autoimports/$ver x86_64 autoimports"
apt-repo add "rpm-src http://mirror.yandex.ru/altlinux/autoimports/$ver noarch autoimports"

apt-get update

# Configure MATE desktop
if [[ $is_docker == 0 && "$DESKTOP_SESSION" == "mate" ]]; then
## install MATE applets for Panel
apt-get install -y mate-applets

## keyboard layouts, Alt+Shift for layout toggle
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['us', 'ru']"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd model "''"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['grp\tgrp:alt_shift_toggle']"

## screensaver
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.screensaver themes "['screensavers-footlogo-floaters']"

## theme
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.interface gtk-theme "'TraditionalOk'"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.interface icon-theme "'mate'"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.general theme "'TraditionalOk'"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-mouse cursor-theme "'mate'"

## workspaces
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.general num-workspaces 4
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.workspace-names name-1 "'Workspace 1'"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.workspace-names name-2 "'Workspace 2'"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.workspace-names name-3 "'Workspace 3'"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.workspace-names name-4 "'Workspace 4'"

## Pluma
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.pluma display-line-numbers true
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.pluma highlight-current-line true
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.pluma auto-detected-encodings "['UTF-8', 'GBK', 'CURRENT', 'ISO-8859-15', 'UTF-16', 'WINDOWS-1251']"


## terminal
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.global-keybindings run-command-terminal "'<Primary><Alt>t'"

cat <<EOF > /tmp/dconf-mate-terminal
[keybindings]
help='disabled'

[global]
use-menu-accelerators=false
use-mnemonics=true

[profiles/default]
allow-bold=false
background-color='#FFFFFFFFDDDD'
palette='#2E2E34343636:#CCCC00000000:#4E4E9A9A0606:#C4C4A0A00000:#34346565A4A4:#757550507B7B:#060698209A9A:#D3D3D7D7CFCF:#555557575353:#EFEF29292929:#8A8AE2E23434:#FCFCE9E94F4F:#72729F9FCFCF:#ADAD7F7FA8A8:#3434E2E2E2E2:#EEEEEEEEECEC'
bold-color='#000000000000'
foreground-color='#000000000000'
visible-name='Default'
scrollback-unlimited=true
EOF
sudo -EHu "$SUDO_USER" -- dconf load /org/mate/terminal/ < /tmp/dconf-mate-terminal

## mate panels layout
cat <<EOF > /tmp/dconf-mate-panel
[general]
object-id-list=['menu-bar', 'notification-area', 'clock', 'show-desktop', 'window-list', 'workspace-switcher', 'object-0', 'object-1', 'object-2', 'object-3']
toplevel-id-list=['top', 'bottom']

[objects/clock]
applet-iid='ClockAppletFactory::ClockApplet'
locked=true
object-type='applet'
panel-right-stick=true
position=0
toplevel-id='top'

[objects/clock/prefs]
custom-format=''
format='24-hour'

[objects/menu-bar]
locked=true
object-type='menu-bar'
position=0
toplevel-id='top'

[objects/notification-area]
applet-iid='NotificationAreaAppletFactory::NotificationArea'
locked=true
object-type='applet'
panel-right-stick=true
position=10
toplevel-id='top'

[objects/object-0]
applet-iid='TrashAppletFactory::TrashApplet'
locked=true
object-type='applet'
panel-right-stick=false
position=1345
toplevel-id='bottom'

[objects/object-1]
applet-iid='MultiLoadAppletFactory::MultiLoadApplet'
locked=true
object-type='applet'
panel-right-stick=false
position=1268
toplevel-id='bottom'

[objects/object-1/prefs]
view-memload=true
view-netload=true

[objects/object-2]
launcher-location='/usr/share/applications/caja-browser.desktop'
locked=true
object-type='launcher'
panel-right-stick=false
position=296
toplevel-id='top'

[objects/object-3]
launcher-location='/usr/share/applications/mate-terminal.desktop'
locked=true
object-type='launcher'
panel-right-stick=false
position=326
toplevel-id='top'

[objects/show-desktop]
applet-iid='WnckletFactory::ShowDesktopApplet'
locked=true
object-type='applet'
position=0
toplevel-id='bottom'

[objects/window-list]
applet-iid='WnckletFactory::WindowListApplet'
locked=true
object-type='applet'
position=20
toplevel-id='bottom'

[objects/workspace-switcher]
applet-iid='WnckletFactory::WorkspaceSwitcherApplet'
locked=true
object-type='applet'
panel-right-stick=false
position=572
toplevel-id='top'

[toplevels/bottom]
expand=true
orientation='bottom'
screen=0
size=24
y=616
y-bottom=0

[toplevels/top]
expand=true
orientation='top'
screen=0
size=24
EOF

sudo -EHu "$SUDO_USER" -- dconf load /org/mate/panel/ < /tmp/dconf-mate-panel


## window management keyboard shortcuts for Ubuntu MATE 18.04 LTS
if [[ "$ver" == "p9" || "$ver" == "p10" ]]; then
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings unmaximize '<Mod4>Down'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings maximize '<Mod4>Up'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-ne '<Alt><Mod4>Right'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-sw '<Shift><Alt><Mod4>Left'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-side-e '<Mod4>Right'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-se '<Shift><Alt><Mod4>Right'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings move-to-center '<Alt><Mod4>c'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-nw '<Alt><Mod4>Left'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-side-w '<Mod4>Left'

    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.global-keybindings run-command-terminal '<Primary><Alt>t'
fi

fi # (is_docker && MATE)?

# temporary fix for https://bugzilla.altlinux.org/43236
cat << \EOF > /etc/profile.d/mate.sh
if [ "$DESKTOP_SESSION" == "mate" ]; then
  if [ -z "$XDG_DATA_DIRS" ]; then
    XDG_DATA_DIRS=/usr/share/mate:/usr/local/share/:/usr/share/
  else
    XDG_DATA_DIRS=/usr/share/mate:"$XDG_DATA_DIRS"
  fi
  export XDG_DATA_DIRS

  if [ -z "$XDG_CONFIG_DIRS" ]; then
    export XDG_CONFIG_DIRS=/etc/xdg/xdg-mate:/etc/xdg
  fi
fi
EOF
chmod +x /etc/profile.d/mate.sh

# temporary fix for p10 - https://bugzilla.altlinux.org/43443
if [ "$ver" == "p10" ]; then
  ln -sf /usr/bin/mate-volume-control-status-icon /usr/local/bin/mate-volume-control-applet
fi

# temporary fix for https://bugzilla.altlinux.org/43466
apt-get remove -y acpid-events-power

# temporary fix for p10 - https://bugzilla.altlinux.org/43403
if [ "$ver" == "p10" ]; then
  apt-get install -y su git etersoft-build-utils rpm-build-vala rpm-build-gir gcc-c++ gperf libncurses-devel libcairo-devel intltool gtk-doc libgio-devel libgtk+3-devel libpango-devel libgnutls-devel vala-tools libvala-devel libpcre2-devel libgladeui2.0-devel gobject-introspection-devel libgtk+3-gir-devel gear

  if [ $is_docker == 1 ]; then
    if [ -z "$SUDO_USER" ]; then
	    SUDO_USER=temp_user
	    useradd $SUDO_USER || true
    fi
  fi

  su -l $SUDO_USER -c "mkdir -p /home/$SUDO_USER/RPM/SOURCES"

  cd /tmp
  rm -rf /tmp/vte3
  su -l $SUDO_USER -c "git clone https://git.altlinux.org/srpms/v/vte3.git -b p9 /tmp/vte3"
  cd vte3
  su -l $SUDO_USER -c "cp /tmp/vte3/*.patch /home/$SUDO_USER/RPM/SOURCES/"

  curr_ver=$(grep "define ver_major" vte3.spec | awk '{print $NF}')
  new_ver=0.99.3really$curr_ver
  sub_ver=$(grep Version vte3.spec | awk -F. '{print $NF}')
  sed -i "s/define ver_major $curr_ver/define ver_major $new_ver/" vte3.spec
  rm -rf .git
  mv vte "vte-$new_ver.3"
  su -l $SUDO_USER -c "cd /tmp/vte3 && tar -cJf vte-$new_ver.$sub_ver.tar.xz vte-$new_ver.$sub_ver/ && cp -v /tmp/vte3/vte-$new_ver.$sub_ver.tar.xz /home/$SUDO_USER/RPM/SOURCES/"

  su -l $SUDO_USER -c "rpmbb /tmp/vte3/vte3.spec"

  rm -v /home/$SUDO_USER/RPM/RPMS/*/*vte*debuginfo*.rpm
  apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/*/*vte*"$new_ver"."$sub_ver"*.rpm || true
  apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/*/*vte*"$new_ver"."$sub_ver"*.rpm

  if [ $is_docker == 1 ]; then
    if [ "$SUDO_USER" == "temp_user" ]; then
	    unset SUDO_USER
	    userdel -r -f temp_user
    fi
  fi

  ## recompile xfce4-terminal and reinstall it to work with patched libvte
  if [[ $is_docker == 0 && "$DESKTOP_SESSION" == "xfce" ]]; then
    if [ "$ver" == "p10" ]; then
      apt-get install -y su etersoft-build-utils rpm-build-xfce4 xfce4-dev-tools libxfconf-devel libxfce4ui-gtk3-devel libpcre2-devel docbook-dtds docbook-style-xsl intltool libvte3-devel xsltproc
      cd /tmp
      apt-get source xfce4-terminal
      su -l $SUDO_USER -c "rpm -i /tmp/xfce4-terminal-*.src.rpm"
      su -l $SUDO_USER -c "rpmbb /home/$SUDO_USER/RPM/SPECS/xfce4-terminal.spec"
      rm -v /home/$SUDO_USER/RPM/RPMS/*/*xfce4-terminal*debuginfo*.rpm
      apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/x86_64/xfce4-terminal-*.rpm || true
      apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/x86_64/xfce4-terminal-*.rpm

      apt-get install -y --reinstall xfce4-default
    fi
  fi
fi #/bug 43403

# temporarary fix for p9, p10 - https://bugzilla.altlinux.org/44100
if [ "$DESKTOP_SESSION" == "mate" ]; then
 if [[ "$ver" == "p9" || "$ver" == "p10" ]]; then
  apt-get install -y su etersoft-build-utils mate-common gtk-doc libSM-devel libXi-devel libXrandr-devel libdbus-glib-devel libdconf-devel libmateweather-devel librsvg-devel libwnck3-devel mate-desktop-devel mate-menus-devel yelp-tools libgtk-layer-shell-devel
  
  if [ $is_docker == 1 ]; then
    if [ -z "$SUDO_USER" ]; then
	    SUDO_USER=temp_user
	    useradd $SUDO_USER || true
    fi
  fi

  su -l $SUDO_USER -c "mkdir -p /home/$SUDO_USER/RPM/SOURCES"

  cd /tmp
  rm -rf /tmp/mp
  mkdir /tmp/mp
  cd /tmp/mp
  apt-get source mate-panel
  rpm2cpio mate-panel-*.src.rpm | cpio -i

  # disable patch
  sed -i 's/^Patch/#Patch/' mate-panel.spec
  sed -i 's/^%patch/#%patch/' mate-panel.spec

  # rebuild and pin
  curr_ver=$(grep Version mate-panel.spec | awk -F: '{print $2}' | tr -d ' ')
  curr_rel=$(grep Release mate-panel.spec | awk -F: '{print $2}' | tr -d ' ')
  su -l $SUDO_USER -c "cp -v /tmp/mp/mate-panel-${curr_ver}.tar /home/$SUDO_USER/RPM/SOURCES/"
  su -l $SUDO_USER -c "cp -v /tmp/mp/libegg*.tar /home/$SUDO_USER/RPM/SOURCES/" || true
  
  chown -R $SUDO_USER: /tmp/mp
  su -l $SUDO_USER -c "rpmbb /tmp/mp/mate-panel.spec"

  rm -v /home/$SUDO_USER/RPM/RPMS/*/*mate-panel*debuginfo*.rpm
  apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/*/*mate-panel*.rpm || true
  apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/*/*mate-panel*.rpm

  cat <<EOF | tee -a /var/lib/preferences
Package: libmate-panel
Pin: version ${curr_ver}-${curr_rel}
Pin-Priority: 1001

Package: mate-panel
Pin: version ${curr_ver}-${curr_rel}
Pin-Priority: 1001

Package: mate-panel-devel
Pin: version ${curr_ver}-${curr_rel}
Pin-Priority: 1001

EOF
ln -sf /var/lib/preferences /etc/apt/preferences.d/synaptic

  if [ $is_docker == 1 ]; then
    if [ "$SUDO_USER" == "temp_user" ]; then
	    unset SUDO_USER
	    userdel -r -f temp_user
    fi
  fi  
 fi #/bug 44100
fi #/MATE

# wget
apt-get install -y wget

# Git
apt-get install -y git

# GVFS backends for Caja and others
apt-get install -y gvfs-backends

# RabbitVCS integration to Caja
if [ "$ver" == "p9" ]; then
    apt-get install -y python-module-caja python-module-dbus python-module-pysvn python-module-dulwich python-module-pygobject3 python-module-configobj python-module-simplejson python-modules-tkinter python-module-setuptools git mercurial subversion
    rvcs_ver=0.16
    python_exe=python
fi
if [ "$ver" == "p10" ]; then
    apt-get install -y python3-module-caja python3-module-dbus python3-module-pysvn python3-module-dulwich python3-module-pygobject3 python3-module-configobj python3-module-simplejson python3-modules-tkinter python3-module-setuptools git mercurial subversion
    rvcs_ver=0.18
    python_exe=python3
fi

cd /tmp
wget -c https://github.com/rabbitvcs/rabbitvcs/archive/refs/tags/v${rvcs_ver}.tar.gz
rm -rf cd rabbitvcs-${rvcs_ver}/ 
tar -xf v${rvcs_ver}.tar.gz
cd rabbitvcs-${rvcs_ver}/
${python_exe} setup.py build
${python_exe} setup.py install --prefix=/usr
cp -avfr clients/cli/rabbitvcs /usr/local/bin/

if [ $is_docker == 0 ]; then
	sudo -u $SUDO_USER -- mkdir -p ~/.local/share/caja-python/extensions
	sudo -u $SUDO_USER -- cp -avfr /tmp/rabbitvcs-${rvcs_ver}/clients/caja/RabbitVCS.py ~/.local/share/caja-python/extensions/
else
	mkdir -p /usr/local/share/caja-python/extensions
	cp -avfr /tmp/rabbitvcs-${rvcs_ver}/clients/caja/RabbitVCS.py /usr/local/share/caja-python/extensions/
fi

# GIMP
apt-get install -y gimp

# Inkscape
apt-get install -y inkscape

# Double Commander
apt-get install -y doublecmd-gtk

# System tools
if [ "$ver" == "p9" ]; then
    apt-get install -y fslint fslint-gnome
fi

apt-get install -y htop mc ncdu aptitude synaptic synaptic-usermode eepm apf menu
#apf update

# Kate text editor
apt-get install -y kde5-kate kde5-profile

# Meld 1.5.3 as in https://askubuntu.com/a/965151/66509 with workaround for https://bugzilla.altlinux.org/44923
apt-get install -y etersoft-build-utils intltool rpm-build-python3 rpm-build-python libnumpy python python-module-numpy python-module-pycairo python-module-pygobject python-module-pygtk python-modules python-modules-bsddb python-modules-compiler python-modules-ctypes python-modules-curses python-modules-email python-modules-encodings python-modules-hotshot python-modules-logging python-modules-multiprocessing python-modules-unittest python-modules-xml python-strict rpm-build-licenses python-devel scrollkeeper python-module-pygtksourceview python-module-pygtk-libglade

if [ $is_docker == 1 ]; then
  if [ -z "$SUDO_USER" ]; then
    SUDO_USER=temp_user
    useradd $SUDO_USER || true
  fi
fi

su -l $SUDO_USER -c "mkdir -p /home/$SUDO_USER/RPM/SOURCES"

cd /tmp
rm -rf /tmp/meld
su -l $SUDO_USER -c "git clone https://git.altlinux.org/srpms/m/meld.git -b 1.5.3-alt1 /tmp/meld"
cd meld

curr_ver=$(grep "define ver_major" meld.spec | awk '{print $NF}')
new_ver=9.99.3really$curr_ver
sub_ver=$(grep Version meld.spec | awk -F. '{print $NF}')
sed -i "s/define ver_major $curr_ver/define ver_major $new_ver/" meld.spec
sed -i "s/gtksourceview/gtksourceview2/" meld.spec
sed -i "s/%gpl2plus/GPL-2.0-or-later/" meld.spec
sed -i "s/python$/python2/" meld/INSTALL
sed -i "s|/usr/bin/env python$|/usr/bin/env python2|" meld/bin/meld meld/tools/check_release meld/tools/install_paths meld/tools/make_release
rm -rf .git
mv meld "meld-$new_ver.3"
su -l $SUDO_USER -c "cd /tmp/meld && tar -cJf meld-$new_ver.$sub_ver.tar.xz meld-$new_ver.$sub_ver/ && cp -v /tmp/meld/meld-$new_ver.$sub_ver.tar.xz /home/$SUDO_USER/RPM/SOURCES/"

su -l $SUDO_USER -c "rpmbb /tmp/meld/meld.spec"

apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/*/*meld*"$new_ver"."$sub_ver"*.rpm || true
apt-get install -y --reinstall /home/$SUDO_USER/RPM/RPMS/*/*meld*"$new_ver"."$sub_ver"*.rpm

if [ $is_docker == 1 ]; then
  if [ "$SUDO_USER" == "temp_user" ]; then
    unset SUDO_USER
    userdel -r -f temp_user
  fi
fi
#/meld

# VirtualBox
apt-get install -y virtualbox virtualbox-guest-additions virtualbox-doc
vbox_version=$(rpm -qa 2>/dev/null | grep -E "^virtualbox\-(5|6|7)" | awk -F'-' '{print $2}')

# NOTE: seems to be better than "epm play virtualbox-extpack" as we get VBox GA ISO too for the same version
if [ -n "$vbox_version" ]; then
  rm -v /usr/share/virtualbox/VBoxGuestAdditions.iso || true
  wget -c "https://download.virtualbox.org/virtualbox/${vbox_version}/VBoxGuestAdditions_${vbox_version}.iso" -O /usr/share/virtualbox/VBoxGuestAdditions.iso || true

  cd /tmp
  wget -c "https://download.virtualbox.org/virtualbox/${vbox_version}/Oracle_VM_VirtualBox_Extension_Pack-${vbox_version}.vbox-extpack" || true
  VBoxManage extpack cleanup
  VBoxManage extpack install --replace "/tmp/Oracle_VM_VirtualBox_Extension_Pack-${vbox_version}.vbox-extpack" --accept-license=33d7284dc4a0ece381196fda3cfe2ed0e1e8e7ed7f27b9a9ebc4ee22e24bd23c
fi

if [ $is_docker == 0 ]; then
	usermod -a -G vboxusers $SUDO_USER
fi

# LibreOffice
apt-get install LibreOffice-still -y

# RStudio for OpenSuSe 15
apt-get install -y libpq5 libsqlite sqlite R-base R-devel R-doc-html

cd /tmp
wget -c https://s3.amazonaws.com/rstudio-ide-build/desktop/opensuse15/x86_64/rstudio-2021.09.3-396-x86_64.rpm

rm -fv /etc/eepm/repack.d/rstudio.sh || true # hack: forget about RStudio in modern versions of eepm (>3.27.0-alt1)
epm install -y --repack /tmp/rstudio-2021.09.3-396-x86_64.rpm
apt-get install --reinstall -y eepm

ln -sf /usr/lib/rstudio/bin/rstudio /usr/local/bin/rstudio

if [ $is_docker == 0 ]; then
	sudo -u $SUDO_USER -- mkdir -p ~/.config/rstudio
	cat <<EOF > ~/.config/rstudio/rstudio-prefs.json 
{
    "check_for_updates": false,
    "pdf_previewer": "rstudio",
    "posix_terminal_shell": "bash",
    "submit_crash_reports": false
}
EOF
	chown $SUDO_USER: ~/.config/rstudio/rstudio-prefs.json

	echo 'crash-handling-enabled="0"' | sudo -u $SUDO_USER -- tee ~/.config/rstudio/crash-handler.conf
else
	mkdir -p /etc/skel/.config/rstudio
	cat <<EOF > /etc/skel/.config/rstudio/rstudio-prefs.json 
{
    "check_for_updates": false,
    "pdf_previewer": "rstudio",
    "posix_terminal_shell": "bash",
    "submit_crash_reports": false
}
EOF

  echo 'crash-handling-enabled="0"' > /etc/skel/.config/rstudio/crash-handler.conf
fi

# Pandoc
cd /tmp
LATEST_PANDOC_DEB_URL="https://github.com/jgm/pandoc/releases/download/2.16.1/pandoc-2.16.1-1-amd64.deb"
wget -c $LATEST_PANDOC_DEB_URL;
epm install -y --repack /tmp/pandoc-2.16.1-1-amd64.deb

# bookdown install for local user
apt-get install -y rpm-build libssl-devel libcurl-devel libxml2-devel libcairo-devel gcc gcc-c++ libfribidi-devel libtiff-devel libjpeg-devel libgit2-devel
apt-get install -y evince

if [ "$ver" == "p9" ]; then
    r_ver="3.6"
fi
if [ "$ver" == "p10" ]; then
    r_ver="4.1"
fi

## install R-packages with specific versions for reproducibility
bookdown_ver="0.37"
knitr_ver="1.45"
xaringan_ver="0.29"

if [ $is_docker == 0 ]; then
	su -l $SUDO_USER -c "mkdir -p /home/$SUDO_USER/R/x86_64-alt-linux-gnu-library/$r_ver"
    su -l $SUDO_USER -c "R -e \"install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/', lib='/home/$SUDO_USER/R/x86_64-alt-linux-gnu-library/$r_ver')\""

    su -l $SUDO_USER -c "R -e \"require(devtools); install_version('bookdown', version = '$bookdown_ver', repos = 'http://cran.r-project.org')\""
	su -l $SUDO_USER -c "R -e \"require(devtools); install_version('knitr', version = '$knitr_ver', repos = 'http://cran.r-project.org')\""
	su -l $SUDO_USER -c "R -e \"require(devtools); install_version('xaringan', version = '$xaringan_ver', repos = 'http://cran.r-project.org/')\""
else
	R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org')"

	R -e "require(devtools); install_version('bookdown', version = '$bookdown_ver', repos = 'http://cran.r-project.org')"
	R -e "require(devtools); install_version('knitr', version = '$knitr_ver', repos = 'http://cran.r-project.org')"
	R -e "require(devtools); install_version('xaringan', version = '$xaringan_ver', repos = 'http://cran.r-project.org/')"
fi

# TexLive and fonts

apt-get install -y texlive-extra-utils biber texlive-lang-cyrillic texlive-xetex texlive-fonts-extra texlive-science font-manager texlive-latex-extra fonts-ttf-ms
apt-get install -y alien dpkg

# Atril with epub support
apt-get install -y libmate-document-viewer mate-document-viewer

## get fonts-cmu from Debian
cd /tmp
wget -c http://mirror.yandex.ru/debian/pool/main/f/fonts-cmu/fonts-cmu_0.7.0-4_all.deb
epm install -y --repack /tmp/fonts-cmu_0.7.0-4_all.deb
rm -vf /tmp/fonts-cmu_0.7.0-4_all.deb

# ReText
apt-get install -y retext

if [ $is_docker == 0 ]; then
	echo mathjax | sudo -u $SUDO_USER -- tee -a ~/.config/markdown-extensions.txt
	chown $SUDO_USER: ~/.config/markdown-extensions.txt
else
	echo mathjax >> /etc/skel/.config/markdown-extensions.txt
fi

# PlayOnLinux
apt-get install -y i586-libGL i586-xorg-dri-{intel,nouveau,radeon,swrast} i586-libncurses i586-libunixODBC2 i586-wine curl p7zip playonlinux winetricks

# Telegram
apt-get install -y telegram-desktop

# NotepadQQ
apt-get install -y notepadqq

# Flatpak
apt-get install -y flatpak flatpak-repo-flathub
control fusermount wheelonly
if [ "$ver" == "p9" ]; then
    chmod a+x /etc/profile.d/flatpak.sh || true
fi

# Snap
if [ $is_docker == 0 ]; then
    if [ "$ver" == "p10" ]; then
        apt-get install -y snapd
        ln -sf /var/lib/snapd/snap /snap
        systemctl enable --now snapd.service
    fi
fi

# AppImage
control fusermount public

# Squid-deb-proxy auto-detect as in https://forum.altlinux.org/index.php?topic=46596
if [ $is_docker == 0 ]; then
  cd /tmp
  wget -c http://mirror.yandex.ru/debian/pool/main/s/squid-deb-proxy/squid-deb-proxy-client_0.8.14+nmu2_all.deb
  apt-get install -y rpm-build-python python-base
  epm install -y --repack ./squid-deb-proxy-client_0.8.14+nmu2_all.deb

  cat <<\EOF | sudo tee /etc/NetworkManager/dispatcher.d/99-squid-deb-proxy-detect
#!/bin/sh

logger -t squid-deb-proxy-detect "start with $2"

[ $# -ge 2 ] && [ "$2" != "up" ] && [ "$2" != "vpn-up" ] && [ "$2" != "connectivity-change" ] && [ "$2" != "dhcp4-change" ] && exit 0

logger -t squid-deb-proxy-detect "launching apt-avahi-discover"
avahi_proxy=$(/usr/share/squid-deb-proxy-client/apt-avahi-discover 2>/dev/null | grep -E "^http|^ftp")

sed -i '/^Acquire::http::Proxy.*/d' /etc/apt/apt.conf

if [ -n "$avahi_proxy" ];
then
	echo "Acquire::http::Proxy \"$avahi_proxy\";" | tee -a /etc/apt/apt.conf >/dev/null
fi

apt_proxy_set=$(grep ^Acquire::http::Proxy /etc/apt/apt.conf)
if [ -n "$apt_proxy_set" ];
then
	logger -t squid-deb-proxy-detect "set $apt_proxy_set"
fi

logger -t squid-deb-proxy-detect "end"
EOF

  chmod +x /etc/NetworkManager/dispatcher.d/99-squid-deb-proxy-detect
fi

# Cleaning up
## fix for https://forum.altlinux.org/index.php?topic=47299
apt-mark manual sudo
apt-get autoremove -y

apt-get install -y apt-scripts
apt-get dedup -y

#remove-old-kernels -y

## Arduino from official site on p9, Fritzing from repo
if [ $is_docker == 0 ]; then
	usermod -a -G dialout $SUDO_USER
	usermod -a -G uucp $SUDO_USER
fi

if [ "$ver" == "p9" ]; then
	cd /tmp
	wget -c https://downloads.arduino.cc/arduino-1.8.19-linux64.tar.xz
	cd /opt
	tar -xf /tmp/arduino-1.8.19-linux64.tar.xz
	cd arduino-1.8.19
	./install.sh

	rm -vf /home/*/Desktop/arduino-arduinoide.desktop /root/Desktop/arduino-arduinoide.desktop /home/*/Рабочий\ стол/arduino-arduinoide.desktop || true
elif [ "$ver" == "p10" ]; then
	apt-get install -y arduino
fi

apt-get install -y fritzing

# Scilab from official site
#scilab_ver=5.5.2 # segfaults, broken
#scilab_ver=6.1.1 # runs normally, no Coselica in ATOMS
scilab_ver=6.0.2
cd /tmp
wget -c https://oos.eu-west-2.outscale.com/scilab-releases/${scilab_ver}/scilab-${scilab_ver}.bin.linux-x86_64.tar.gz
cd /opt
tar -xzf /tmp/scilab-${scilab_ver}.bin.linux-x86_64.tar.gz
cd scilab-${scilab_ver}
ln -sf /opt/scilab-${scilab_ver}/bin/XML2Modelica /usr/local/bin/XML2Modelica
ln -sf /opt/scilab-${scilab_ver}/bin/scilab-bin /usr/local/bin/scilab-bin
ln -sf /opt/scilab-${scilab_ver}/bin/modelicac /usr/local/bin/modelicac
ln -sf /opt/scilab-${scilab_ver}/bin/scilab /usr/local/bin/scilab
ln -sf /opt/scilab-${scilab_ver}/bin/scinotes /usr/local/bin/scinotes
ln -sf /opt/scilab-${scilab_ver}/bin/xcos /usr/local/bin/xcos
ln -sf /opt/scilab-${scilab_ver}/bin/scilab-cli-bin /usr/local/bin/scilab-cli-bin
ln -sf /opt/scilab-${scilab_ver}/bin/modelicat /usr/local/bin/modelicat

mkdir -p /usr/local/share/applications
cp -avrfu share/{icons,applications,mime} /usr/local/share/
update-mime-database /usr/local/share/mime/
update-menus

echo "ALT Linux post-install script finished! Reboot to apply all new settings and enjoy newly installed software."

exit 0
